// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "foo",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "foo",
            /// MUST be static for iOS and dynamic for Android. The script takes care of that.
            type: .dynamic,
            targets: ["foo"]
        ),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.4.4"),
        .package(url: "https://source.skip.tools/skip-fuse.git", from: "1.0.2"),
    ],
    targets: [
        .target(
            name: "foo",
            dependencies: [
                .product(name: "SkipFuse", package: "skip-fuse"),
            ],
            plugins: [
                .plugin(name: "skipstone", package: "skip")
            ]
        ),
        .testTarget(
            name: "fooTests",
            dependencies: ["foo"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
