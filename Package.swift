// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Boostlingo",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "Boostlingo",
            targets: ["Boostlingo"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/moozzyk/SignalR-Client-Swift", from: "1.1.0"),
        .package(url: "https://github.com/twilio/twilio-voice-ios", from: "6.13.1"),
        .package(url: "https://github.com/twilio/twilio-video-ios", from: "5.9.0")
    ],
    targets: [
        .binaryTarget(
            name: "Boostlingo",
            url: "https://github.com/boostlingo/boostlingo-ios/releases/download/v2.0.0/Boostlingo.xcframework.zip",
            checksum: "840df792419c29a2c0007c828691422df432425545fa80f77604b56013e78d93"
        ),
    ]
)
