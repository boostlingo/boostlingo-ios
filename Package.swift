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
        .package(url: "https://github.com/twilio/twilio-voice-ios", from: "6.13.2"),
        .package(url: "https://github.com/twilio/twilio-video-ios", from: "5.9.0")
    ],
    targets: [
        .binaryTarget(
            name: "Boostlingo",
            url: "https://github.com/boostlingo/boostlingo-ios/releases/download/2.0.0/Boostlingo.xcframework.zip",
            checksum: "838764a66c8617bb930d4321af798f8e2d0c86795d4b4119801f32f940b5f8a3"
        ),
    ]
)