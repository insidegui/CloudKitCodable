// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "CloudKitCodable",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .tvOS(.v14),
        .watchOS(.v7)
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
