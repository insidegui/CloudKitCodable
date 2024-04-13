import Foundation
import CloudKitCodable

struct TestModelCustomAsset: Hashable, CustomCloudKitCodable {
    struct Contents: Identifiable, Hashable, CloudKitAssetValue {
        var id: String
        var contentProperty1: String
        var contentProperty2: String
        var contentProperty3: String
        var contentProperty4: String
    }
    var cloudKitSystemFields: Data?
    var title: String
    var contents: Contents
}

extension TestModelCustomAsset {
    static let test = TestModelCustomAsset(
        title: "Hello Title",
        contents: .init(
            id: "MyID",
            contentProperty1: "Prop1",
            contentProperty2: "Prop2",
            contentProperty3: "Prop3",
            contentProperty4: "Prop4"
        )
    )
}
