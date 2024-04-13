//
//  CloudKitRecordEncoderTests.swift
//  CloudKitRecordEncoderTests
//
//  Created by Guilherme Rambo on 11/05/18.
//  Copyright © 2018 Guilherme Rambo. All rights reserved.
//

import XCTest
import CloudKit
@testable import CloudKitCodable

final class CloudKitRecordEncoderTests: XCTestCase {

    func testComplexPersonStructEncoding() throws {
        let record = try CloudKitRecordEncoder().encode(Person.rambo)

        try _validateRamboFields(in: record)
    }

    func testCustomZoneIDEncoding() throws {
        let zoneID = CKRecordZone.ID(zoneName: "ABCDE", ownerName: CKCurrentUserDefaultName)

        let record = try CloudKitRecordEncoder(zoneID: zoneID).encode(Person.rambo)
        try _validateRamboFields(in: record)

        XCTAssert(record.recordID.zoneID == zoneID)
    }

    func testSystemFieldsEncoding() throws {
        var previouslySavedRambo = Person.rambo

        previouslySavedRambo.cloudKitSystemFields = CKRecord.systemFieldsDataForTesting

        let record = try CloudKitRecordEncoder().encode(previouslySavedRambo)

        XCTAssertEqual(record.recordID.recordName, "RecordABCD")
        XCTAssertEqual(record.recordID.zoneID.zoneName, "ZoneABCD")
        XCTAssertEqual(record.recordID.zoneID.ownerName, "OwnerABCD")

        try _validateRamboFields(in: record)
    }

    func testCustomRecordIdentifierEncoding() throws {
        let zoneID = CKRecordZone.ID(zoneName: "ABCDE", ownerName: CKCurrentUserDefaultName)

        let record = try CloudKitRecordEncoder(zoneID: zoneID).encode(PersonWithCustomIdentifier.rambo)

        XCTAssert(record.recordID.zoneID == zoneID)
        XCTAssert(record.recordID.recordName == "MY-ID")
    }

    func testEnumEncoding() throws {
        let model = TestModelWithEnum.allEnumsPopulated

        let record = try CloudKitRecordEncoder().encode(model)

        XCTAssertEqual(record["enumProperty"], "enumCase3")
        XCTAssertEqual(record["optionalEnumProperty"], "enumCase2")
        XCTAssertEqual(record["intEnumProperty"], 1)
        XCTAssertEqual(record["optionalIntEnumProperty"], 2)
    }

    func testEnumEncodingNilValue() throws {
        let model = TestModelWithEnum.optionalEnumNil

        let record = try CloudKitRecordEncoder().encode(model)

        XCTAssertEqual(record["enumProperty"], "enumCase3")
        XCTAssertNil(record["optionalEnumProperty"])
        XCTAssertEqual(record["intEnumProperty"], 1)
        XCTAssertNil(record["optionalIntEnumProperty"])
    }

    func testNestedEncoding() throws {
        let model = TestParent.test

        let record = try CloudKitRecordEncoder().encode(model)

        let encodedChild = """
        {"name":"Hello Child Name","value":"Hello Child Value"}
        """.UTF8Data()

        XCTAssertEqual(record["parentName"], "Hello Parent")
        XCTAssertEqual(record["child"], encodedChild)
    }

    func testNestedEncodingCollection() throws {
        let model = TestParentCollection.test

        let record = try CloudKitRecordEncoder().encode(model)

        let encodedChildren = """
        [{"name":"0 - Hello Child Name","value":"0 - Hello Child Value"},{"name":"1 - Hello Child Name","value":"1 - Hello Child Value"},{"name":"2 - Hello Child Name","value":"2 - Hello Child Value"}]
        """.UTF8Data()

        XCTAssertEqual(record["parentName"], "Hello Parent Collection")
        XCTAssertEqual(record["children"], encodedChildren)
    }

}

extension String {
    func UTF8Data() -> Data { Data(utf8) }
}
