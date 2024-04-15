//
//  CloudKitRecordEncoder.swift
//  CloudKitCodable
//
//  Created by Guilherme Rambo on 11/05/18.
//  Copyright © 2018 Guilherme Rambo. All rights reserved.
//

import Foundation
import CloudKit

public enum CloudKitRecordEncodingError: Error {
    case unsupportedValueForKey(String)
    case systemFieldsDecode(String)
    case referencesNotSupported(String)
    case dataFieldTooLarge(key: String, size: Int)

    public var localizedDescription: String {
        switch self {
        case .unsupportedValueForKey(let key):
            return """
                   The value of key \(key) is not supported. Only values that can be converted to
                   CKRecordValue are supported. Check the CloudKit documentation to see which types
                   can be used.
                   """
        case .systemFieldsDecode(let info):
            return "Failed to process \(_CKSystemFieldsKeyName): \(info)"
        case .referencesNotSupported(let key):
            return "References are not supported by CloudKitRecordEncoder yet. Key: \(key)."
        case .dataFieldTooLarge(let key, let size):
            return "Value for child data \"\(key)\" of \(size) bytes exceeds maximum of \(CKRecord.maxDataSize) bytes"
        }
    }
}

public class CloudKitRecordEncoder {
    public var zoneID: CKRecordZone.ID?

    public func encode(_ value: Encodable) throws -> CKRecord {
        let type = recordTypeName(for: value)
        let name = recordName(for: value)

        let encoder = _CloudKitRecordEncoder(recordTypeName: type, zoneID: zoneID, recordName: name)

        try value.encode(to: encoder)

        return encoder.record
    }

    private func recordTypeName(for value: Encodable) -> String {
        if let customValue = value as? CustomCloudKitEncodable {
            return customValue.cloudKitRecordType
        } else {
            return String(describing: type(of: value))
        }
    }

    private func recordName(for value: Encodable) -> String {
        if let customValue = value as? CustomCloudKitEncodable {
            return customValue.cloudKitIdentifier
        } else {
            return UUID().uuidString
        }
    }

    public init(zoneID: CKRecordZone.ID? = nil) {
        self.zoneID = zoneID
    }
}

final class _CloudKitRecordEncoder {
    let zoneID: CKRecordZone.ID?
    let recordTypeName: String
    let recordName: String

    init(recordTypeName: String, zoneID: CKRecordZone.ID?, recordName: String) {
        self.recordTypeName = recordTypeName
        self.zoneID = zoneID
        self.recordName = recordName
    }

    var codingPath: [CodingKey] = []

    var userInfo: [CodingUserInfoKey : Any] = [:]

    fileprivate var container: CloudKitRecordEncodingContainer?
}

extension CodingUserInfoKey {
    static let targetRecord = CodingUserInfoKey(rawValue: "TargetRecord")!
}

extension _CloudKitRecordEncoder: Encoder {
    var record: CKRecord {
        if let existingRecord = container?.record { return existingRecord }

        let zid = zoneID ?? CKRecordZone.ID(zoneName: CKRecordZone.ID.defaultZoneName, ownerName: CKCurrentUserDefaultName)
        let rid = CKRecord.ID(recordName: recordName, zoneID: zid)

        return CKRecord(recordType: recordTypeName, recordID: rid)
    }

    fileprivate func assertCanCreateContainer() {
        precondition(self.container == nil)
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        assertCanCreateContainer()

        let container = KeyedContainer<Key>(recordTypeName: self.recordTypeName,
                                            zoneID: self.zoneID,
                                            recordName: self.recordName,
                                            codingPath: self.codingPath,
                                            userInfo: self.userInfo)
        self.container = container

        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Not implemented")
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("Not implemented")
    }
}

protocol CloudKitRecordEncodingContainer: AnyObject {
    var record: CKRecord? { get }
}

extension _CloudKitRecordEncoder {
    final class KeyedContainer<Key> where Key: CodingKey {
        let recordTypeName: String
        let zoneID: CKRecordZone.ID?
        let recordName: String
        var metaRecord: CKRecord?
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        fileprivate var storage: [String: CKRecordValue] = [:]

        init(recordTypeName: String,
             zoneID: CKRecordZone.ID?,
             recordName: String,
             codingPath: [CodingKey],
             userInfo: [CodingUserInfoKey : Any])
        {
            self.recordTypeName = recordTypeName
            self.zoneID = zoneID
            self.recordName = recordName
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
}

extension _CloudKitRecordEncoder.KeyedContainer: KeyedEncodingContainerProtocol {
    func encodeNil(forKey key: Key) throws {
        storage[key.stringValue] = nil
    }

    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        guard key.stringValue != _CKSystemFieldsKeyName else {
            guard let systemFields = value as? Data else {
                throw CloudKitRecordEncodingError.systemFieldsDecode("\(_CKSystemFieldsKeyName) property must be of type Data")
            }

            try prepareMetaRecord(with: systemFields)

            return
        }

        storage[key.stringValue] = try produceCloudKitValue(for: value, withKey: key)
    }

    private func produceCloudKitValue<T>(for value: T, withKey key: Key) throws -> CKRecordValue where T : Encodable {
        if let urlValue = value as? URL {
            return produceCloudKitValue(for: urlValue)
        } else if let collection = value as? [Any] {
            /// The `value as? CKRecordValue` cast in the next `else if` will always succeed for arrays,
            /// so here we check that the value is actually an array where the elements conform to `CKRecordValue`,
            /// then return it as an `NSArray`. Otherwise, this is an array with arbitrary `Encodable` elements,
            /// in which case they'll be stored as a single data field with the JSON-encoded representation.
            if let ckValueArray = collection as? [CKRecordValue] {
                return ckValueArray as NSArray
            } else {
                return try encodedChildValue(for: value, withKey: key)
            }
        } else if let ckValue = value as? CKRecordValue {
            return ckValue
        } else if let stringValue = (value as? any CloudKitStringEnum)?.rawValue {
            return stringValue as NSString
        } else if let intValue = (value as? any CloudKitIntEnum)?.rawValue {
            return NSNumber(value: Int(intValue))
        } else {
            return try encodedChildValue(for: value, withKey: key)
        }
    }

    private func encodedChildValue<T>(for value: T, withKey key: Key) throws -> CKRecordValue where T : Encodable {
        if let customAssetValue = value as? CloudKitAssetValue {
            let asset = try customAssetValue.createAsset()
            return asset
        } else {
            let encodedChild = try JSONEncoder.nestedCloudKitValue.encode(value)

            guard encodedChild.count < CKRecord.maxDataSize else {
                throw CloudKitRecordEncodingError.dataFieldTooLarge(key: key.stringValue, size: encodedChild.count)
            }

            return encodedChild as NSData
        }
    }

    private func prepareMetaRecord(with systemFields: Data) throws {
        let coder = try NSKeyedUnarchiver(forReadingFrom: systemFields)
        coder.requiresSecureCoding = true
        metaRecord = CKRecord(coder: coder)
        coder.finishDecoding()
    }

    private func produceCloudKitValue(for url: URL) -> CKRecordValue {
        if url.isFileURL {
            return CKAsset(fileURL: url)
        } else {
            return url.absoluteString as CKRecordValue
        }
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError("Not implemented")
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("Not implemented")
    }

    func superEncoder() -> Encoder {
        fatalError("Not implemented")
    }

    func superEncoder(forKey key: Key) -> Encoder {
        fatalError("Not implemented")
    }
}

extension _CloudKitRecordEncoder.KeyedContainer: CloudKitRecordEncodingContainer {

    var recordID: CKRecord.ID {
        let zid = zoneID ?? CKRecordZone.ID(zoneName: CKRecordZone.ID.defaultZoneName, ownerName: CKCurrentUserDefaultName)
        return CKRecord.ID(recordName: recordName, zoneID: zid)
    }

    var record: CKRecord? {
        let output: CKRecord

        if let metaRecord = self.metaRecord {
            output = metaRecord
        } else {
            output = CKRecord(recordType: recordTypeName, recordID: recordID)
        }

        guard output.recordType == recordTypeName else {
            fatalError(
                """
                CloudKit record type mismatch: the record should be of type \(recordTypeName) but it was
                of type \(output.recordType). This is probably a result of corrupted cloudKitSystemData
                or a change in record/type name that must be corrected in your type by adopting CustomCloudKitEncodable.
                """
            )
        }

        for (key, value) in storage {
            output[key] = value
        }

        return output
    }

}

extension JSONEncoder {
    static let nestedCloudKitValue: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        return e
    }()
}

extension PropertyListEncoder {
    static let nestedCloudKitValueBinary: PropertyListEncoder = {
        let e = PropertyListEncoder()
        e.outputFormat = .binary
        return e
    }()

    static let nestedCloudKitValueXML: PropertyListEncoder = {
        let e = PropertyListEncoder()
        e.outputFormat = .xml
        return e
    }()
}

private extension CKRecord {
    /// The entire `CKRecord` can't exceed 1MB, but since we don't really know how large the whole
    /// record is, we just check data fields to ensure that they fit within the limit. This doesn't prevent
    /// the record from exceeding the 1MB limit, but at least catches the most egregious attempts.
    static let maxDataSize = 1_000_000
}

// MARK: - CloudKitAssetValue Support

private extension CloudKitAssetValue {
    func createAsset() throws -> CKAsset {
        let data = try encoded()

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        try data.write(to: tempURL)

        return CKAsset(fileURL: tempURL)
    }
}
