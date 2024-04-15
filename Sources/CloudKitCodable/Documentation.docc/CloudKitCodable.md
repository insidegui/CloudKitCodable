# ``CloudKitCodable``

This library provides encoding and decoding of custom value types to and from `CKRecord`, making it a lot easier to transfer custom data types between your app and CloudKit.

## Overview

To make a type `CKRecord`-compatible, you implement the ``CustomCloudKitCodable`` protocol, which is composed of the ``CustomCloudKitEncodable`` and ``CustomCloudKitDecodable`` protocols.

Encoding and decoding uses the same mechanism as `Codable`, but instead of using something like `JSONEncoder` and `JSONDecoder`, you use ``CloudKitRecordEncoder`` and ``CloudKitRecordDecoder``.
The encoder takes your custom data type as input and produces a corresponding `CKRecord`, and the decoder takes an existing `CKRecord` and produces an instance of your custom type.

## Quick Start

For a simple example, see <doc:Example>.

To familiarize yourself with how different data types are encoded and decoded, see <doc:DataTypes>.

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
