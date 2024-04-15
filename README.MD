# CloudKit + Codable = ❤️

[![Badge showing the current build status](https://github.com/insidegui/CloudKitCodable/actions/workflows/swift-package.yml/badge.svg)](https://github.com/insidegui/CloudKitCodable/actions/workflows/swift-package.yml)

This project implements a `CloudKitRecordEncoder` and a `CloudKitRecordDecoder` so you can easily convert your custom data structure to a `CKRecord` and convert your `CKRecord` back to your custom data structure.

## Usage

### `CustomCloudKitCodable`

The types you want to convert to/from `CKRecord` must implement the `CustomCloudKitCodable` protocol. This is necessary because unlike most implementations of encoders/decoders, we are not converting to/from `Data`, but to/from `CKRecord`, which has some special requirements.

There are also two other protocols: `CustomCloudKitEncodable` and `CustomCloudKitDecodable`. You can use those if you only need either encoding or decoding respectively.

The protocol requires two properties on the type you want to convert to/from `CKRecord`:

```swift
var cloudKitSystemFields: Data? { get }
```

This will be used to store the system fields for the `CKRecord` when decoding. The system fields contain metadata for the record such as its unique identifier and they're very important when syncing.

```swift
var cloudKitRecordType: String { get }
```

This property should return the record type for your custom type. It's implemented automatically to return the name of the type, you only need to implement this if you need to customize the record type.

### Data Types

CloudKit imposes some limits on the types of data that can be stored as part of a `CKRecord`. CloudKitCodable attempts to use the best supported representation for any given property, but you should be aware of the limitations.

#### Enumerations

CloudKitCodable can encode and decode `enum` properties that are backed by either a `String` or `Int` raw value.

In order for the enum encoding to work, your enum must conform to `CloudKitStringEnum` or `CloudKitIntEnum`, the only requirement being a static `cloudKitFallbackCase` property that determines the default value for the property in case the `CKRecord` contains a raw value that can't initialize the enum.

This is important because if you add new cases to the enum, then it's possible for an older version of your app to get an enum case that it doesn't know about.

#### URLs
There's special handling for URLs because of the way CloudKit works with files. If you have a property that's a remote `URL` (i.e. a website), it's encoded as a `String` (CloudKit doesn't support URLs natively) and decoded back as a `URL`. 

If your property is a `URL` and it contains a `URL` to a local file, it is encoded as a `CKAsset`, the file will be automatically uploaded to CloudKit when you save the containing record and downloaded when you get the record from the cloud. The decoded `URL` will contain the `URL` for the location on disk where CloudKit has downloaded the file.

### Example

Let's say you have a `Person` model you want to sync to CloudKit. This is what the model would look like:

```swift
struct Person: CustomCloudKitCodable {
    var cloudKitSystemFields: Data?
    let name: String
    let age: Int
    let website: URL
    let avatar: URL
    let isDeveloper: Bool
}
```

Notice I didn't implement `cloudKitRecordType`, in that case, the `CKRecord` type for this model will be `Person` (the name of the type itself).

Now, before saving the record to CloudKit, we encode it:

```swift
let rambo = Person(
    cloudKitSystemFields: nil,
    name: "Guilherme Rambo",
    age: 26,
    website: URL(string:"https://guilhermerambo.me")!,
    avatar: URL(fileURLWithPath: "/Users/inside/Pictures/avatar.png"),
    isDeveloper: true
)

do {
   let record = try CloudKitRecordEncoder().encode(rambo)
   // record is now a CKRecord you can upload to CloudKit
} catch {
   // something went wrong
}
```

Since `avatar` points to a local file, the corresponding file will be uploaded as a `CKAsset` when the record is saved to CloudKit and downloaded back when the record is retrieved.

To decode the record:

```swift
let record = // record obtained from CloudKit
do {
   let person = try CloudKitRecordDecoder().decode(Person.self, from: record)
} catch {
   // something went wrong
}
```

## Minimum Deployment Targets

- iOS 14
- tvOS 14
- watchOS 5
- macOS 11
- Xcode 15 (recommended)

## Installation

### Swift Package Manager

Add CloudKitCodable to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/insidegui/CloudKitCodable.git", from: "0.2.0")
]
```

### Manually

If you prefer not to use Swift Package Manager, you can integrate CloudKitCodable into your project manually by copying the files in.
