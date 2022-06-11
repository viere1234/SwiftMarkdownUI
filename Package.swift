// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftMarkdownUI",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SwiftMarkdownUI",
            targets: ["SwiftMarkdownUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown", branch: "main"),
        .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "0.5.3"),
        .package(url: "https://github.com/gonzalezreal/NetworkImage", from: "4.0.0"),
        .package(url: "https://github.com/gonzalezreal/AttributedText", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SwiftMarkdownUI",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "CombineSchedulers", package: "combine-schedulers"),
                "NetworkImage",
                "AttributedText",
            ]),
        .testTarget(
            name: "SwiftMarkdownUITests",
            dependencies: ["SwiftMarkdownUI"]),
    ]
)
