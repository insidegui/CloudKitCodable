//
//  Person.swift
//  CloudKitCodableTests
//
//  Created by Guilherme Rambo on 11/05/18.
//  Copyright © 2018 Guilherme Rambo. All rights reserved.
//

import Foundation
import CloudKitCodable

struct Person: CustomCloudKitCodable, Equatable {
    var cloudKitSystemFields: Data?
    let name: String
    let age: Int
    let website: URL
    let avatar: URL
    let isDeveloper: Bool

    static func ==(lhs: Person, rhs: Person) -> Bool {
        return
               lhs.name        == rhs.name
            && lhs.age         == rhs.age
            && lhs.website     == rhs.website
            && lhs.avatar      == rhs.avatar
            && lhs.isDeveloper == rhs.isDeveloper
    }
}

struct PersonWithCustomIdentifier: CustomCloudKitCodable {
    var cloudKitSystemFields: Data?
    var cloudKitIdentifier: String
    let name: String
}
