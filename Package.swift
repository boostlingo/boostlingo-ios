// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "BoostlingoSDK",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "BoostlingoSDK",
            targets: ["BoostlingoSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/moozzyk/SignalR-Client-Swift", from: "1.1.0"),
        .package(url: "https://github.com/twilio/twilio-voice-ios", from: "6.13.1"),
        .package(url: "https://github.com/twilio/twilio-video-ios", from: "5.9.0")
    ],
    targets: [
        .binaryTarget(
            name: "BoostlingoSDK",
            url: "https://github.com/boostlingo/boostlingo-ios/releases/download/v2.0.0/Boostlingo.xcframework.zip",
            checksum: "ac49e83bb618960497a3aff02a0c6ab364aa2d06aa43bd4e0cfe5cac68545a0e"
        ),
    ]
)