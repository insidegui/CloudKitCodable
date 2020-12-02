//
//  CloudKitRecordDecoder.swift
//  CloudKitCodable
//
//  Created by Guilherme Rambo on 12/05/18.
//  Copyright © 2018 Guilherme Rambo. All rights reserved.
//

import Foundation
import CloudKit

final public class CloudKitRecordDecoder {
    public func decode<T>(_ type: T.Type, from record: CKRecord) throws -> T where T : Decodable {
        let decoder = _CloudKitRecordDecoder(record: record)
        return try T(from: decoder)
    }

    public init() { }
}

final class _CloudKitRecordDecoder {
    var codingPath: [CodingKey] = []

    var userInfo: [CodingUserInfoKey : Any] = [:]

    var container: CloudKitRecordDecodingContainer?
    fileprivate var record: CKRecord

    init(record: CKRecord) {
        self.record = record
    }
}

extension _CloudKitRecordDecoder: Decoder {
    fileprivate func assertCanCreateContainer() {
        precondition(self.container == nil)
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedDecodingContainer<Key> where Key : CodingKey {
        assertCanCreateContainer()

        let container = KeyedContainer<Key>(record: self.record, codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedDecodingContainer {
        fatalError("Not implemented")
    }

    func singleValueContainer() -> SingleValueDecodingContainer {
        fatalError("Not implemented")
    }
}

protocol CloudKitRecordDecodingContainer: class {
    var codingPath: [CodingKey] { get set }

    var userInfo: [CodingUserInfoKey : Any] { get }

    var record: CKRecord { get set }
}

extension _CloudKitRecordDecoder {
    final class KeyedContainer<Key> where Key: CodingKey {
        var record: CKRecord
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        private lazy var systemFieldsData: Data = {
            return decodeSystemFields()
        }()

        func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
            return self.codingPath + [key]
        }

        init(record: CKRecord, codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.record = record
        }

        func checkCanDecodeValue(forKey key: Key) throws {
            guard self.contains(key) else {
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "key not found: \(key)")
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
}

extension _CloudKitRecordDecoder.KeyedContainer: KeyedDecodingContainerProtocol {
    var allKeys: [Key] {
        return self.record.allKeys().compactMap { Key(stringValue: $0) }
    }

    func contains(_ key: Key) -> Bool {
        guard key.stringValue != _CKSystemFieldsKeyName else { return true }

        return allKeys.contains(where: { $0.stringValue == key.stringValue })
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        try checkCanDecodeValue(forKey: key)

        if key.stringValue == _CKSystemFieldsKeyName {
            return systemFieldsData.count == 0
        } else {
            return record[key.stringValue] == nil
        }
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        try checkCanDecodeValue(forKey: key)

        print("decode key: \(key.stringValue)")

        if key.stringValue == _CKSystemFieldsKeyName {
            return systemFieldsData as! T
        }

        if key.stringValue == _CKIdentifierKeyName {
            return record.recordID.recordName as! T
        }

        // Bools are encoded as Int64 in CloudKit
        if type == Bool.self {
            return try decodeBool(forKey: key) as! T
        }

        // URLs are encoded as String (remote) or CKAsset (file URL) in CloudKit
        if type == URL.self {
            return try decodeURL(forKey: key) as! T
        }

        guard let value = record[key.stringValue] as? T else {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "CKRecordValue couldn't be converted to \(String(describing: type))'")
            throw DecodingError.typeMismatch(type, context)
        }

        return value
    }

    private func decodeURL(forKey key: Key) throws -> URL {
        if let asset = record[key.stringValue] as? CKAsset {
            guard let url = decodeURL(from: asset) else {
                throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "CKAsset must have a URL")
            }

            return url
        }

        guard let str = record[key.stringValue] as? String else {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "URL should have been encoded as String in CKRecord")
            throw DecodingError.typeMismatch(URL.self, context)
        }

        guard let url = URL(string: str) else {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "The string \(str) is not a valid URL")
            throw DecodingError.typeMismatch(URL.self, context)
        }

        return url
    }

    private func decodeURL(from asset: CKAsset) -> URL? {
        return asset.fileURL
    }

    private func decodeBool(forKey key: Key) throws -> Bool {
        guard let intValue = record[key.stringValue] as? Int64 else {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Bool should have been encoded as Int64 in CKRecord")
            throw DecodingError.typeMismatch(Bool.self, context)
        }

        return intValue == 1
    }

    private func decodeSystemFields() -> Data {
        let data = NSMutableData()
        let coder = NSKeyedArchiver.init(forWritingWith: data)
        coder.requiresSecureCoding = true
        record.encodeSystemFields(with: coder)
        coder.finishEncoding()

        return data as Data
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        fatalError("Not implemented")
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("Not implemented")
    }

    func superDecoder() throws -> Decoder {
        return _CloudKitRecordDecoder(record: record)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        let decoder = _CloudKitRecordDecoder(record: self.record)
        decoder.codingPath = [key]

        return decoder
    }
}

extension _CloudKitRecordDecoder.KeyedContainer: CloudKitRecordDecodingContainer {}
