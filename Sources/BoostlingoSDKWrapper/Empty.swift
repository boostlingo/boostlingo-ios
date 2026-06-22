// Intentionally empty.
//
// This wrapper target exists solely to attach the TwilioVoice, TwilioVideo,
// and SignalRClient dependencies to the BoostlingoSDKBinary xcframework, which —
// being a binaryTarget — cannot declare dependencies itself. Without this, a
// consumer on a Swift toolchain other than the one the SDK was built with fails
// to recompile BoostlingoSDK from its .swiftinterface ("no such module
// 'TwilioVideo'"). Consumers still `import BoostlingoSDK`; this module is empty
// and carries no public API.
