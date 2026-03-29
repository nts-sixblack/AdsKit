// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "AdsKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "AdsKit",
            targets: ["AdsKit"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            from: "13.1.0"
        ),
        .package(
            url: "https://github.com/nts-sixblack/SwiftInjected.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "AdsKit",
            dependencies: [
                .product(
                    name: "GoogleMobileAds",
                    package: "swift-package-manager-google-mobile-ads"
                ),
                .product(
                    name: "SwiftInjected",
                    package: "SwiftInjected"
                )
            ],
            path: "Sources/AdsKit",
            resources: [
                .process("Resources/Media.xcassets"),
                .process("Resources/Assets.xcassets"),
                .copy("Resources/PackageMetadata.json")
            ]
        ),
        .testTarget(
            name: "AdsKitTests",
            dependencies: ["AdsKit"],
            path: "Tests/AdsKitTests"
        )
    ]
)
