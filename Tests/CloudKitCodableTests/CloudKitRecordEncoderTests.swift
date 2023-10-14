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

}
