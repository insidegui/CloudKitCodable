import Foundation
import CloudKit
import UniformTypeIdentifiers

/// Adopted by `Codable` types that can be nested in ``CustomCloudKitCodable`` types, represented as `CKAsset` in records.
///
/// The corresponding `CKRecord` field is encoded as a `CKAsset` with a file containing the encoded representation of the value.
///
/// Implementers can customize the encoding/decoding, file type, and asset file name, but there are default implementations for all of this protocol's requirements.
public protocol CloudKitAssetValue: Codable {

    /// The default content type for `CKAsset` files representing values of this type.
    ///
    /// There's a default implementation that returns `.json`, so by default ``CloudKitAssetValue`` types are encoded as JSON.
    static var preferredContentType: UTType { get }

    /// The preferred filename for this value when being encoded as a `CKAsset`.
    ///
    /// There's a default implementation for a filename with the format `<type>-<uuid>.(json/plist)`,
    /// and a default implementation for `Identifiable` types that uses the `id` property instead of a random UUID.
    var filename: String { get }

    /// Encodes this value as data.
    ///
    /// There's a default implementation that uses `JSONEncoder`/`PropertyListDecoder` according to the ``preferredContentType`` property.
    func encoded() throws -> Data

    /// Decodes an instance of this type from encoded data.
    /// - Parameters:
    ///   - data: The encoded value data.
    ///   - type: Determines the type of decoder to be used.
    /// - Returns: The instance of the type.
    ///
    /// There is a default implementation supporting JSON and PLIST types that uses `JSONDecoder`/`PropertyListDecoder`.
    static func decoded(from data: Data, type: UTType) throws -> Self
}

// MARK: - Default Implementations

public extension CloudKitAssetValue {
    /// Default implementation that returns `.json`, so the value is encoded as JSON data.
    static var preferredContentType: UTType { .json }
}

public extension CloudKitAssetValue {
    /// The file extension (including the leading `.`), computed according to ``preferredContentType``.
    static var filenameSuffix: String { Self.preferredContentType.preferredFilenameExtension.flatMap { ".\($0)" } ?? "" }

    /// The file name (including extension) for this value when encoded into a `CKAsset`.
    var filename: String { [String(describing: Self.self), UUID().uuidString].joined(separator: "-") + Self.filenameSuffix }
}

public extension CloudKitAssetValue where Self: Identifiable {
    /// The file name (including extension) for this value when encoded into a `CKAsset`.
    /// Uses the `id` property from `Identifiable` conformance.
    var filename: String { [String(describing: Self.self), String(describing: id)].joined(separator: "-") + Self.filenameSuffix }
}

public extension CloudKitAssetValue {
    func encoded() throws -> Data {
        let type = Self.preferredContentType
        if type.conforms(to: .json) {
            return try JSONEncoder.nestedCloudKitValue.encode(self)
        } else if type.conforms(to: .xmlPropertyList) {
            return try PropertyListEncoder.nestedCloudKitValueXML.encode(self)
        } else if type.conforms(to: .binaryPropertyList) {
            return try PropertyListEncoder.nestedCloudKitValueBinary.encode(self)
        } else if type.conforms(to: .propertyList) {
            return try PropertyListEncoder.nestedCloudKitValueXML.encode(self)
        } else {
            throw EncodingError.invalidValue(self, .init(codingPath: [], debugDescription: "Unsupported content type \"\(type.identifier)\": the default implementation only supports JSON and PLIST"))
        }
    }

    static func decoded(from data: Data, type: UTType) throws -> Self {
        if type.conforms(to: .json) {
            return try JSONDecoder.nestedCloudKitValue.decode(Self.self, from: data)
        } else if type.conforms(to: .propertyList) {
            return try PropertyListDecoder.nestedCloudKitValue.decode(Self.self, from: data)
        } else {
            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "Unsupported content type \"\(type.identifier)\": the default implementation only supports JSON and PLIST"))
        }
    }
}
