# ``CloudKitCodable``

This library provides encoding and decoding of custom value types to and from `CKRecord`, making it a lot easier to transfer custom data types between your app and CloudKit.

## Overview

To make a type `CKRecord`-compatible, you implement the ``CustomCloudKitCodable`` protocol, which is composed of the ``CustomCloudKitEncodable`` and ``CustomCloudKitDecodable`` protocols.

Encoding and decoding uses the same mechanism as `Codable`, but instead of using something like `JSONEncoder` and `JSONDecoder`, you use ``CloudKitRecordEncoder`` and ``CloudKitRecordDecoder``.
The encoder takes your custom data type as input and produces a corresponding `CKRecord`, and the decoder takes an existing `CKRecord` and produces an instance of your custom type.

## Example

Here's an example of a custom data type that implements ``CustomCloudKitCodable``:

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

The only requirement I had to implement in this example was the ``CloudKitRecordRepresentable/cloudKitSystemFields`` property, which is used to store metadata from CloudKit that's fetched alongside the `CKRecord`.

If you plan on using your model as a way to sync user data with CloudKit, then you're probably storing it locally using something like a database. If that's the case, then it's important that you also store the value of `cloudKitSystemFields` after fetching a record from CloudKit, or after uploading the model for the first time. That way CloudKit can keep track of the data and allow you to address issues such as sync conflicts.  

Let's say I want to upload a `Person` record to CloudKit, this is how I would do it:

```swift
let rambo = Person(
    cloudKitSystemFields: nil,
    name: "Guilherme Rambo",
    age: 32,
    website: URL(string:"https://rambo.codes")!,
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

This is how I would decode a `CKRecord` representing a `Person`:

```swift
let record = // record obtained from CloudKit
do {
   let person = try CloudKitRecordDecoder().decode(Person.self, from: record)
} catch {
   // something went wrong
}
```

## Topics

### Implementing Support for `CKRecord` in Your Models

- ``CustomCloudKitCodable``

### Encoding and Decoding Records

- ``CloudKitRecordEncoder``
- ``CloudKitRecordDecoder``

### Supporting Custom Types and Assets

- ``CloudKitStringEnum``
- ``CloudKitIntEnum``
- ``CloudKitAssetValue``
