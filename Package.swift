// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "BoostlingoSDK",
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
            url: "https://github.com/boostlingo/boostlingo-ios/releases/download/2.0.0/Boostlingo.xcframework.zip",
            checksum: "8e92569fd32329e1edc78c5c96dcecf9eff96bd817f7da37e74968a5559b048c"
        ),
    ]
)