//
//  CustomCloudKitEncodable.swift
//  CloudKitCodable
//
//  Created by Guilherme Rambo on 11/05/18.
//  Copyright © 2018 Guilherme Rambo. All rights reserved.
//

import Foundation
import CloudKit

internal let _CKSystemFieldsKeyName = "cloudKitSystemFields"
internal let _CKIdentifierKeyName = "cloudKitIdentifier"

/// Base protocol for types that can be represented as a `CKRecord`.
///
/// This protocol is the base for both ``CustomCloudKitEncodable`` and ``CustomCloudKitDecodable``.
/// 
/// Its only requirement that doesn't have a default implementation is ``CloudKitRecordRepresentable/cloudKitSystemFields``, which is a required
/// property for all types that can be encoded as a `CKRecord` and decoded from a `CKRecord`.
///
/// The ``CloudKitRecordRepresentable/cloudKitRecordType`` and ``CloudKitRecordRepresentable/cloudKitIdentifier``
/// allow you to customize the CloudKit record type and record name.
///
/// - note: You probably don't want to conform to `CloudKitRecordRepresentable` by itself.
/// Declare conformance to ``CustomCloudKitCodable`` instead, which will include the requirements from this protocol,
/// as well as support for encoding/decoding.
public protocol CloudKitRecordRepresentable {

    /// Stores metadata about the `CKRecord` for this value.
    ///
    /// After a `CKRecord` is uploaded to CloudKit, or when a `CKRecord` is initially downloaded from CloudKit,
    /// decoding it with ``CloudKitRecordDecoder`` will populate this property with metadata about the `CKRecord`.
    ///
    /// If you're using CloudKit's sync functionality, then you want to keep this metadata around so that new instances of `CKRecord`
    /// created from the same value of your custom data type are recognized by CloudKit as being the same "instance" of that record type.
    ///
    /// - Important: If you're using CloudKit to keep local and remote data in sync between devices, then it's extremely important that you
    /// store this data with your model, be it on a database, the filesystem, or wherever you're storing local data. Doing this ensures that CloudKit's sync
    /// functionality will recognize the model across devices and allow for conflict resolution, preventing issues with duplicated records or data getting out of sync.
    /// If you're just storing/retrieving data on the public database or just not using CloudKit's advanced sync capabilities, then it's less important to keep this metadata around.
    /// Think of whether you're going to be uploading the same "instance" of your model to CloudKit multiple times, for example to update some of its properties.
    /// If that's the case, then you should make sure that this metadata is present when encoding your updated model prior to uploading it to CloudKit again.
    var cloudKitSystemFields: Data? { get }

    /// The `recordType` for this type when encoded as a `CKRecord`.
    ///
    /// When you encode a custom data type into a `CKRecord` with ``CloudKitRecordEncoder``,
    /// the encoder uses the value of this property when constructing the `CKRecord`, passing it as the record's `recordType`.
    ///
    /// **Default implementation**: ``cloudKitRecordType-79t3x``
    var cloudKitRecordType: String { get }

    /// The `recordName` for this type when encoded as a `CKRecord`.
    ///
    /// When you encode a custom data type into a `CKRecord` with ``CloudKitRecordEncoder``,
    /// the encoder uses the value of this property for its `recordName`, which is the canonical identifier for a record on CloudKit.
    ///
    /// If you already have an identifier for your model, then you'll probably want to implement this and return the value for that identifier,
    /// so that it's easier to match between local values and their corresponding `CKRecord` on CloudKit.
    var cloudKitIdentifier: String { get }
}

public extension CloudKitRecordRepresentable {

    /// The `recordType` using the type's name.
    ///
    /// This default implementation uses the name of your type as the `recordType` when encoding it as a `CKRecord`.
    ///
    /// For example, if you have a `Person` type, then the `recordType` of a `CKRecord` representing an instance of `Person`
    /// will be — you guessed it — `Person`.
    var cloudKitRecordType: String {
        return String(describing: type(of: self))
    }

    /// A random `UUID` to be used as the `recordName`.
    ///
    /// This default implementation generates a random `UUID` that's used as the `recordName` of a `CKRecord` when encoding your type.
    ///
    /// - note: If you already have a unique identifier for your data type, then you probably want to implement this property, returning your existing identifier.
    ///
    /// **Default implementation**: ``cloudKitIdentifier-uk1q``
    var cloudKitIdentifier: String {
        return UUID().uuidString
    }
}

/// Implemented by types that can be encoded into `CKRecord` with ``CloudKitRecordEncoder``.
///
/// See ``CloudKitRecordRepresentable`` for details.
public protocol CustomCloudKitEncodable: CloudKitRecordRepresentable & Encodable { }

/// Implemented by types that can be decoded from a `CKRecord` with ``CloudKitRecordDecoder``.
///
/// See ``CloudKitRecordRepresentable`` for details.
public protocol CustomCloudKitDecodable: CloudKitRecordRepresentable & Decodable { }

/// Implemented by types that can be encoded and decoded to/from `CKRecord` with ``CloudKitRecordEncoder`` and ``CloudKitRecordDecoder``.
///
/// See ``CloudKitRecordRepresentable`` for details.
public protocol CustomCloudKitCodable: CustomCloudKitEncodable & CustomCloudKitDecodable { }
