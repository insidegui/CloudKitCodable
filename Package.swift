// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "CloudKitCodable",
    platforms: [
        .macOS(.v10_12), .iOS(.v11),
    ],
    products: [
        .library(name: "CloudKitCodable", targets: ["CloudKitCodable"])
    ],
    targets: [
        .target(name: "CloudKitCodable", path: "CloudKitCodable/Source"),
        // Until resources are supported, this test doesn't work
        //.testTarget(name: "CloudKitCodableTests", dependencies: ["CloudKitCodable"])
    ],
    swiftLanguageVersions: [.v4]
)
