import Foundation
import CloudKit
import UniformTypeIdentifiers

/// Adopted by `Codable` types that can be nested in ``CustomCloudKitCodable`` types, represented as `CKAsset` in records.
///
/// You implement `CloudKitAssetValue` for `Codable` types that can be used as properties of a type conforming to ``CustomCloudKitCodable``.
/// 
/// This allows ``CloudKitRecordEncoder`` to encode the nested type as a `CKAsset` containing a (by default) JSON-encoded representation of the value.
/// When decoding with ``CloudKitRecordDecoder``, the local file downloaded from CloudKit is then read and decoded back as the corresponding value.
///
/// Implementations can customize the encoding/decoding, file type, and asset file name, but there are default implementations for all of this protocol's requirements.
public protocol CloudKitAssetValue: Codable {

    /// The default content type for `CKAsset` files representing values of this type.
    ///
    /// When using the default implementations of ``CloudKitAssetValue/encoded()`` and  ``CloudKitAssetValue/decoded(from:type:)``,
    /// the preferred content type determines which encoder/decoder is used for the value:
    ///
    /// - `.json`: uses `JSONEncoder` and `JSONDecoder`
    /// - `.xmlPropertyList`: uses `PropertyListEncoder` (XML) and `PropertyListDecoder`
    /// - `.binaryPropertyList`: uses `PropertyListEncoder` (binary) and `PropertyListDecoder`
    ///
    /// There's a default implementation that returns `.json`, so by default ``CloudKitAssetValue`` types are encoded as JSON.
    ///
    /// - Important: Changing the content type after you ship a version of your app to production is not recommended, but if you do, ``CloudKitRecordDecoder`` tries to determine the content type
    /// based on the asset downloaded from CloudKit, using the declared type as a fallback.
    static var preferredContentType: UTType { get }

    /// The file name for this value when being encoded as a `CKAsset`.
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
    /// The default implementation uses `JSONDecoder`/`PropertyListDecoder` depending upon the `type`.
    /// For more details, see the documentation for ``preferredContentType-8zbfl``.
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

    /// Encodes the nested value.
    /// - Returns: The encoded data.
    ///
    /// This default implementation uses ``preferredContentType-8zbfl`` in order to determine which encoder to use.
    /// For more details, see the documentation for ``preferredContentType-8zbfl``.
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
    
    /// Decodes the nested value using data fetched from CloudKit.
    /// - Parameters:
    ///   - data: The encoded data fetched from CloudKit.
    ///   - type: The `UTType` of the data.
    /// - Returns: A decoded instance of the type.
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
