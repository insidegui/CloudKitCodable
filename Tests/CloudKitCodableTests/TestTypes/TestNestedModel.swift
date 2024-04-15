import Foundation
import CloudKitCodable

struct TestParent: CustomCloudKitCodable, Hashable {
    struct TestChild: Codable, Hashable {
        var name: String
        var value: String
    }
    var cloudKitSystemFields: Data?
    var parentName: String
    var child: TestChild
    var dataProperty: Data
}

struct TestParentOptionalChild: CustomCloudKitCodable, Hashable {
    struct TestOptionalChild: Codable, Hashable {
        var name: String
        var value: String
    }
    var cloudKitSystemFields: Data?
    var parentName: String
    var child: TestOptionalChild?
    var dataProperty: Data
}

struct TestParentCollection: CustomCloudKitCodable, Hashable {
    struct TestCollectionChild: Codable, Hashable {
        var name: String
        var value: String
    }
    var cloudKitSystemFields: Data?
    var parentName: String
    var children: [TestCollectionChild]
    /// This data property is used to ensure that the special handling of `Data` for JSON-encoded children
    /// does not break encoding/decoding of regular data fields.
    var dataProperty: Data
}

extension TestParent {
    static let test = TestParent(
        parentName: "Hello Parent",
        child: .init(
            name: "Hello Child Name",
            value: "Hello Child Value"
        ),
        dataProperty: Data([0xFF])
    )
}

extension TestParentOptionalChild {
    static let test = TestParentOptionalChild(
        parentName: "Hello Parent",
        child: .init(
            name: "Hello Optional Child Name",
            value: "Hello Optional Child Value"
        ),
        dataProperty: Data([0xFF])
    )
    static let testNilChild = TestParentOptionalChild(
        parentName: "Hello Parent",
        child: nil,
        dataProperty: Data([0xFF])
    )
}

extension TestParentCollection {
    static let test = TestParentCollection(
        parentName: "Hello Parent Collection",
        children: [
            .init(
                name: "0 - Hello Child Name",
                value: "0 - Hello Child Value"
            ),
            .init(
                name: "1 - Hello Child Name",
                value: "1 - Hello Child Value"
            ),
            .init(
                name: "2 - Hello Child Name",
                value: "2 - Hello Child Value"
            ),
        ],
        dataProperty: Data([0xFF])
    )
}
