# CloudKit + Codable = ❤️

[![Badge showing the current build status](https://github.com/insidegui/CloudKitCodable/actions/workflows/swift-package.yml/badge.svg)](https://github.com/insidegui/CloudKitCodable/actions/workflows/swift-package.yml)

This project implements `CloudKitRecordEncoder` and `CloudKitRecordDecoder`, allowing for custom data types to be converted to/from `CKRecord` automatically.

## Usage

For details on how to use CloudKitCodable, please check the included documentation.

### Example

Declaring a model that can be encoded as a `CKRecord`:

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

Creating a `CKRecord` from a `CustomCloudKitCodable` type:

```swift
let rambo = Person(...)

do {
   let record = try CloudKitRecordEncoder().encode(rambo)
   // record is now a CKRecord you can upload to CloudKit
} catch {
   // something went wrong
}
```

Decoding a `CustomCloudKitCodable` type from a `CKRecord`:

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
    .package(url: "https://github.com/insidegui/CloudKitCodable.git", from: "0.3.0")
]
```

### Manually

If you prefer not to use Swift Package Manager, you can integrate CloudKitCodable into your project manually by copying the files in.
