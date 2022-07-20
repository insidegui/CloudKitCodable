// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "CloudKitCodable",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
        .tvOS(.v13)
    ],
    products: [
        .library(name: "CloudKitCodable", targets: ["CloudKitCodable"])
    ],
    targets: [
        .target(name: "CloudKitCodable"),
        .testTarget(
            name: "CloudKitCodableTests",
            dependencies: ["CloudKitCodable"],
            resources: [
                .copy("Fixtures/Rambo.ckrecord")
            ]
        )
    ]
)
