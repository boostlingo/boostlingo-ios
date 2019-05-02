# Boostlingo iOS

The Boostlingo iOS swift library enables developers to embed the Boostlingo caller directly into their own applications. This can then be used for placing calls in the Boostlingo platform.

## Getting Started

In order to place calls in Boostlingo, you must have a requestor account. You can then embed Boostlingo iOS into your application, request a Boostlingo API token from your server, and start making calls.

## Installation

The Boostlingo iOS framework can be installed using [Cartfile](https://github.com/Carthage/Carthage).
You can add Programmable Voice for iOS by adding the following line to your Cartfile:

```sh
github "boostlingo/boostlingo-ios"
```

Then run `carthage bootstrap` (or `carthage update` if you are updating your SDKs).

On your application targets’ “General” settings tab, in the “Linked Frameworks and Libraries” section, drag and drop each framework you want to use from the Carthage/Build folder on disk.

On your application targets’ “Build Phases” settings tab, click the “+” icon and choose “New Run Script Phase”. Create a Run Script in which you specify your shell (ex: `/bin/sh`), add the following contents to the script area below the shell:

```sh
/usr/local/bin/carthage copy-frameworks
```

Add the paths to the frameworks you want to use under “Input Files":

```sh
$(SRCROOT)/Carthage/Build/iOS/Alamofire.framework
$(SRCROOT)/Carthage/Build/iOS/Moya.framework
$(SRCROOT)/Carthage/Build/iOS/Result.framework
$(SRCROOT)/Carthage/Build/iOS/TwilioVoice.framework
$(SRCROOT)/Carthage/Build/iOS/Boostlingo.framework
```

Add the paths to the copied frameworks to the “Output Files”:

```sh
$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/Alamofire.framework
$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/Moya.framework
$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/Result.framework
$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/TwilioVoice.framework
$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/Boostlingo.framework
```