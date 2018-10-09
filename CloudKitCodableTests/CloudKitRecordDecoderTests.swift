//
//  CloudKitRecordDecoderTests.swift
//  CloudKitCodableTests
//
//  Created by Guilherme Rambo on 12/05/18.
//  Copyright © 2018 Guilherme Rambo. All rights reserved.
//

import XCTest
import CloudKit
@testable import CloudKitCodable

final class CloudKitRecordDecoderTests: XCTestCase {

    private func _validateDecodedPerson(_ person: Person) {
        XCTAssertEqual(person, Person.rambo)
        XCTAssertNotNil(person.cloudKitSystemFields, "\(_CKSystemFieldsKeyName) should bet set for a value conforming to CloudKitRecordRepresentable decoded from an existing CKRecord")
    }

    func testComplexPersonStructDecoding() throws {
        let person = try CloudKitRecordDecoder().decode(Person.self, from: CKRecord.testRecord)

        _validateDecodedPerson(person)
    }

    func testRoundTrip() throws {
        let encodedPerson = try CloudKitRecordEncoder().encode(Person.rambo)
        let samePersonDecoded = try CloudKitRecordDecoder().decode(Person.self, from: encodedPerson)

        _validateDecodedPerson(samePersonDecoded)
    }

    func testRoundTripWithCustomZoneID() throws {
        let zoneID = CKRecordZone.ID(zoneName: "ABCDE", ownerName: CKCurrentUserDefaultName)
        let encodedPerson = try CloudKitRecordEncoder(zoneID: zoneID).encode(Person.rambo)
        let samePersonDecoded = try CloudKitRecordDecoder().decode(Person.self, from: encodedPerson)
        let samePersonReencoded = try CloudKitRecordEncoder().encode(samePersonDecoded)

        _validateDecodedPerson(samePersonDecoded)

        XCTAssert(encodedPerson.recordID.zoneID == samePersonReencoded.recordID.zoneID)
    }

    func testCustomRecordIdentifierRoundTrip() throws {
        let zoneID = CKRecordZone.ID(zoneName: "ABCDE", ownerName: CKCurrentUserDefaultName)

        let record = try CloudKitRecordEncoder(zoneID: zoneID).encode(PersonWithCustomIdentifier.rambo)

        XCTAssert(record.recordID.zoneID == zoneID)
        XCTAssert(record.recordID.recordName == "MY-ID")

        let samePersonDecoded = try CloudKitRecordDecoder().decode(PersonWithCustomIdentifier.self, from: record)
        XCTAssert(samePersonDecoded.cloudKitIdentifier == "MY-ID")
    }

}
