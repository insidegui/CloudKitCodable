# Data Types

How CloudKitCodable handles different data types when dealing with `CKRecord` encoding/decoding.

CloudKit [imposes some limits](https://developer.apple.com/documentation/cloudkit/ckrecord) on what data types can be stored in a `CKRecord`, as well as the maximum size for all data associated with an individual record.

CloudKitCodable tries to handle most of these limitations automatically, but if you're looking to encode and decode complex types to/from `CKRecord`, then there's additional work you can do to make sure that everything works correctly.

## Primitive Types

Simple types such as `String` and `Int` work as you would expect: they're simply stored in the `CKRecord` as-is.

## URL

There's no native support for `URL` in `CKRecord`, and CloudKitCodable handles URLs differently depending upon whether the `URL` is a local file URL, or a remote web URL.

### Local File URLs

When ``CloudKitRecordEncoder`` encounters a property with a `URL` pointing to a local file, the corresponding property on the `CKRecord` will be encoded as a [CKAsset](https://developer.apple.com/documentation/cloudkit/ckasset).

So in order to upload a file to CloudKit, you can have the corresponding property be a `URL` pointing to the local file, and it will be uploaded when saving the record.

The opposite occurs when decoding a record downloaded from CloudKit: ``CloudKitRecordDecoder`` will find the `CKAsset` and set the `URL` property to point to the local file URL downloaded by CloudKit.

### Remote Web URLs

When the `URL` property being encoded has a web URL such as `https://apple.com`, it will be encoded into the `CKRecord` as a `String` containing its absolute string. Upon decoding, the string is then parsed as a `URL`.

### Custom Enumerations

CloudKitCodable can encode and decode `enum` properties that are backed by either a `String` or `Int` raw value.

In order for the enum encoding to work, your enum must conform to ``CloudKitStringEnum`` or ``CloudKitIntEnum``, the only requirement being a static ``CloudKitEnum/cloudKitFallbackCase`` property that determines the default value for the property in case the `CKRecord` contains a raw value that can't initialize the enum.

### Nested Codable Values

Sometimes models have properties that use small value types with a few of their own properties, and you might want to store such models on CloudKit as well.

To enable this, CloudKitCodable will detect properties that have a custom `Codable` type and set the corresponding `CKRecord` field to be a `Data` value with the JSON-encoded representation of the value.

> Important: If your model has a property with a `Codable` type that can potentially become large when encoded, or if your model has more than a couple of properties with `Codable` types, then you should adopt ``CloudKitAssetValue`` instead so that the properties can be represented as a `CKAsset`, which doesn't run the risk of bumping into the 1MB per-record size limit.

### Arrays

All primitive types that are supported in `CKRecord` array fields are also supported by CloudKitCodable.

Nested codable values can also be stored as an array, which will become an array of JSON-encoded `Data` in the `CKRecord`.

> Note: Types conforming to ``CloudKitAssetValue`` **are not** currently supported in arrays.

> Note: Collection types other than `Array` are not supported.
