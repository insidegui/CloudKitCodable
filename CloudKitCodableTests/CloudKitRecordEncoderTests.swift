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

        _validateRamboFields(in: record)
    }

    func testCustomZoneIDEncoding() throws {
        let zoneID = CKRecordZone.ID(zoneName: "ABCDE", ownerName: CKCurrentUserDefaultName)

        let record = try CloudKitRecordEncoder(zoneID: zoneID).encode(Person.rambo)
        _validateRamboFields(in: record)

        XCTAssert(record.recordID.zoneID == zoneID)
    }

    func testSystemFieldsEncoding() throws {
        var previouslySavedRambo = Person.rambo

        previouslySavedRambo.cloudKitSystemFields = CKRecord.systemFieldsDataForTesting

        let record = try CloudKitRecordEncoder().encode(previouslySavedRambo)

        XCTAssertEqual(record.recordID.recordName, "RecordABCD")
        XCTAssertEqual(record.recordID.zoneID.zoneName, "ZoneABCD")
        XCTAssertEqual(record.recordID.zoneID.ownerName, "OwnerABCD")

        _validateRamboFields(in: record)
    }

    func testCustomRecordIdentifierEncoding() throws {
        let zoneID = CKRecordZone.ID(zoneName: "ABCDE", ownerName: CKCurrentUserDefaultName)

        let record = try CloudKitRecordEncoder(zoneID: zoneID).encode(PersonWithCustomIdentifier.rambo)

        XCTAssert(record.recordID.zoneID == zoneID)
        XCTAssert(record.recordID.recordName == "MY-ID")
    }
    
}
