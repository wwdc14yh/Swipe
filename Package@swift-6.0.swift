// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Swipe",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Swipe",
            targets: ["Swipe"]),
        .library(name: "UIComponentSwipe", targets: ["UIComponentSwipe"]),
    ],
    dependencies: [
        .package(url: "https://github.com/lkzhao/UIComponent.git", .upToNextMajor(from: "3.0.0"))
    ],
    targets: [
        .target(name: "Swipe"),
        .target(
            name: "UIComponentSwipe",
            dependencies: [
                "Swipe",
                .product(name: "UIComponent", package: "UIComponent")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
