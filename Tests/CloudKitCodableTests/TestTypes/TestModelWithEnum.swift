import Foundation
import CloudKitCodable

struct TestModelWithEnum: CustomCloudKitCodable, Hashable {
    enum MyStringEnum: String, CloudKitStringEnum, CaseIterable {
        case enumCase0
        case enumCase1
        case enumCase2
        case enumCase3
    }
    enum MyIntEnum: Int, CloudKitIntEnum, CaseIterable {
        case enumCase0
        case enumCase1
        case enumCase2
        case enumCase3
    }
    var cloudKitSystemFields: Data?
    var enumProperty: MyStringEnum
    var optionalEnumProperty: MyStringEnum?
    var intEnumProperty: MyIntEnum
    var optionalIntEnumProperty: MyIntEnum?
}

extension TestModelWithEnum {
    static let allEnumsPopulated = TestModelWithEnum(
        enumProperty: .enumCase3,
        optionalEnumProperty: .enumCase2,
        intEnumProperty: .enumCase1,
        optionalIntEnumProperty: .enumCase2
    )
    static let optionalEnumNil = TestModelWithEnum(
        enumProperty: .enumCase3,
        optionalEnumProperty: nil,
        intEnumProperty: .enumCase1,
        optionalIntEnumProperty: nil
    )
}
