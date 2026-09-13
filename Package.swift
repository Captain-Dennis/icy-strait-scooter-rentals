// swift-tools-version: 5.9
// Linux-checkable slice of the shared lot pipe. iOS UI and CloudKit stay in the Xcode targets.
import PackageDescription

let package = Package(
    name: "IcyStraitShared",
    platforms: [
        .macOS(.v13),
        .iOS(.v17)
    ],
    products: [
        .library(name: "IcyStraitShared", targets: ["IcyStraitShared"])
    ],
    targets: [
        .target(
            name: "IcyStraitShared",
            path: "Shared"
        )
    ]
)
