// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "BoostlingoSDK",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "BoostlingoSDK",
            targets: ["BoostlingoSDKWrapper"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/moozzyk/SignalR-Client-Swift", from: "1.2.1"),
        .package(url: "https://github.com/twilio/twilio-voice-ios", from: "6.13.6"),
        .package(url: "https://github.com/twilio/twilio-video-ios", from: "5.11.3")
    ],
    targets: [
        .binaryTarget(
            name: "BoostlingoSDKBinary",
            url: "https://github.com/boostlingo/boostlingo-ios/releases/download/2.1.1/BoostlingoSDK.xcframework.zip",
            checksum: "52bbaa6f6a784933d51e474b2a52e125357be99e9e213190aba1181974776722"
        ),
        .target(
            name: "BoostlingoSDKWrapper",
            dependencies: [
                "BoostlingoSDKBinary",
                .product(name: "SignalRClient", package: "SignalR-Client-Swift"),
                .product(name: "TwilioVoice",   package: "twilio-voice-ios"),
                .product(name: "TwilioVideo",   package: "twilio-video-ios"),
            ],
            path: "Sources/BoostlingoSDKWrapper"
        ),
    ]
)
