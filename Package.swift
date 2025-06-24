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
        .package(url: "https://github.com/twilio/twilio-voice-ios", from: "6.13.2"),
        .package(url: "https://github.com/twilio/twilio-video-ios", from: "5.9.0")
    ],
    targets: [
        .binaryTarget(
            name: "BoostlingoSDK",
            url: "https://github.com/boostlingo/boostlingo-ios/releases/download/2.0.0/BoostlingoSDK.xcframework.zip",
            checksum: "7402ea13662884cd992fd4103664b0ee61f76e784876cf1fa7cc0e497d643ebb"
        ),
    ]
)