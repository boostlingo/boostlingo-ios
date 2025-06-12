# ``BoostlingoSDK``

The Boostlingo iOS Swift library enables developers to embed the Boostlingo caller directly into their own applications. This can then be used for placing calls in the Boostlingo platform.

## Getting Started

In order to place calls in Boostlingo, you must have a requestor account. You can then embed Boostlingo iOS SDK into your application, request a Boostlingo API token from your server, and start making calls.

## Installation

### Swift Package Manager (recommended)

You can add this SDK to your project using [Swift Package Manager](https://swift.org/package-manager/):

1. In Xcode, go to **File > Add Packages...**
2. Enter the repository URL: https://github.com/boostlingo/boostlingo-ios.git
3. Select the version you want to install and add the package to your target.

Or add it directly to your `Package.swift` dependencies:
```swift
dependencies: [
 .package(url: "https://github.com/boostlingo/boostlingo-ios.git", from: "2.0.0")
]
```

### CocoaPods

It's easy to install the framework if you manage your dependencies using [CocoaPods](https://cocoapods.org/). Simply add the following to your Podfile:

```sh
source 'https://github.com/cocoapods/specs'

target 'TARGET_NAME' do
  use_frameworks!

  pod 'BoostlingoSDK', '2.0.0'
end
```

Then run `pod install` to install the dependencies to your project.

## Usage

These steps will guide you through the basic process of placing calls through Boostlingo.

### Request Boostlingo authentication token

First step is to obtain a boostlingo authentication token from your server.  Never store an API token or username/password in your front end/mobile code.  Your server should be the one that logs the user in, obtains the authentication token, and passes it back down to the web application.

### Obtain Boostlingo authentication token via API endpoint

```json
POST https://app.boostlingo.com/api/web/account/signin
```

Request Model

```json
{
"email": "<string>",
"password": "<string>"
}
```

Response Model
`token` is what will be needed by the boostlingo sdk

```json
{
"userAccountId": "<integer>",
"refreshToken": "<string>",
"role": "<string>",
"token": "<string>",
"companyAccountId": "<integer>"
}
```

### Quickstart

This is a working example that will demonstrate how to make Boostlingo calls.
Update the placeholder of TOKEN with the token you got from the API.

```swift
let boostlingo = BoostlingoSDK(authToken: "your token", region: "us", logger: BLPrintLogger())
```

### Create instance of Boostlingo class and load dictionaries

Async `initialize()` method must be called after creating an instance of `BoostlingoSDK` to ensure all internal services are fully configured and ready to use. The library will cache specific data and create instances of classes that do not need to be refreshed very frequently. The next step is typically to pull down the call dictionaries. Whether you expose these directly or are just mapping languages and service types with your internal types, loading these lists will almost definitely be required.

```swift
// For production builds use BLNullLogger() or your custom logger.
let boostlingo = BoostlingoSDK(
    authToken: authToken,
    region: "us",
    logger: BLPrintLogger()
)
try await boostlingo.initialize()

// Pulling down the call dictionaries.
let dictionaries = try await boostlingo.getCallDictionaries()
let languages = dictionaries?.languages ?? []
let serviceTypes = dictionaries?.serviceTypes ?? []
let genders = dictionaries?.genders ?? []
```

### Disposing Boostlingo SDK after use

Async `dispose()` method should be used when you are finished using the SDK to ensure that all internal resources, such as network connections, memory, and background tasks, are properly released. After calling `dispose()`, the SDK instance should not be used again.

```swift
 await boostlingo.dispose()
```

### Retrieving the pre-call custom Form

You can use the `getPreCallCustomForm` method to fetch the custom form configuration required before starting a call. This form may include fields that the user needs to fill out prior to initiating a call.
The `getPreCallCustomForm` method returns a `PreCallCustomForm` object containing the form fields and metadata. If the form cannot be retrieved, the method will throw an error.

```swift
do {
    let form = try await boostlingo.getPreCallCustomForm()
    // Present the form to the user.
    print("Form title: \(form.title)")
    for field in form.fields {
        print("Field: \(field.label) (\(field.type))")
    }
} catch {
    print("Failed to fetch pre-call custom form: \(error)")
}

...

let fields = form.fields.map({ customField in
    CustomFieldDto(
        fieldId: customField.fieldId,
        value: // User answer.
    )
}) ?? []

...

let callRequest = CallRequest(
    languageFromId: selectedLanguageFrom,
    languageToId: selectedLanguageTo,
    serviceTypeId: selectedServiceType,
    genderId: selectedGender,
    isVideo: isVideo,
    data: [AdditionalField(key: "CustomKey", value: "CustomValue")],
    fieldData: fields // Use your user responses here.
)
```

#### Custom form fields

```swift
public struct CheckBoxCustomField: CustomField, Hashable {
    
    public let fieldId: Int64
    public let fieldTypeId: Int
    public let label: String
    public let readonly: Bool
    public let required: Bool
    public var value: [Int64]?
    public let options: [CustomFieldOption]
}

public struct EditTextCustomField: CustomField, Hashable {
    
    public let fieldId: Int64
    public let fieldTypeId: Int
    public let label: String
    public let readonly: Bool
    public let required: Bool
    public var value: String?
    public let fieldType: FieldType
}

public struct ListMultipleCustomField: CustomField, Hashable {
    
    public let fieldId: Int64
    public let fieldTypeId: Int
    public let label: String
    public let readonly: Bool
    public let required: Bool
    public var value: [Int64]?
    public let options: [CustomFieldOption]
}

public struct ListSingleCustomField: CustomField, Hashable {
    
    public let fieldId: Int64
    public let fieldTypeId: Int
    public let label: String
    public let readonly: Bool
    public let required: Bool
    public var value: Int64?
    public let options: [CustomFieldOption]
}

public struct RadioButtonCustomField: CustomField, Hashable {
    
    public let fieldId: Int64
    public let fieldTypeId: Int
    public let label: String
    public let readonly: Bool
    public let required: Bool
    public var value: Int64?
    public let options: [CustomFieldOption]
}
```

### Calls

Before placing a call you will need to check record permission. It's required to To initiate a voice call, use the `makeVoiceCall` or `makeVideoCall` methods provided by the SDK.

#### Observing call events

The SDK provides a `callEventStream` property of type `AsyncStream<BLCallFlowEvent>`, which allows you to observe call events in a modern, Swift-concurrency-friendly way.

Instead of using weak delegates or callback protocols, you can use `callEventStream` to asynchronously receive updates about the call lifecycle, such as connection status, participant changes, or errors.

```swift
func subscribeOnCallEvents() async {
    let callEventTask = Task {
        for await event in await state.boostlingo.callEventStream {
            guard !Task.isCancelled else { break }
            switch event {
            case .callDidConnect(let call, participants: _): break
            case .callDidDisconnect(let error):
                await cancelSubscriptions()
            case .callDidFailToConnect(let error):
                await cancelSubscriptions()
            case .participantConnected(let participant, call: let call): break
            case .participantUpdated(let participant, call: let call): break
            case .participantDisconnected(let participant, call: let call): break
            @unknown default: break
            }
        }
    }
    await state.setCallEventTask(callEventTask)
}

// You should cancel the subscriptions once the call is finished.
func cancelSubscriptions() async {
    await state.callEventsTask?.cancel()
    await state.chatEventTask?.cancel()
    await state.setCallEventTask(nil)
    await state.setChatEventTask(nil)
}
```

#### Observing chat events

The SDK provides a `chatEventStream` property of type `AsyncStream<BLChatFlowEvent>`, which allows you to observe chat events in a modern, Swift-concurrency-friendly way.

```swift
func subscribeOnChatEvents() async {
    let chatEventTask = Task {
        for await event in await state.boostlingo.chatEventStream {
            guard !Task.isCancelled else { break }
            switch event {
            case .chatConnected: break
            case .chatDisconnected: break
            case .chatMessageReceived(let message):
                print("Chat: \(message.text)")
            @unknown default: break
            }
        }
    }
    await state.setChatEventTask(chatEventTask)
}

// You should cancel the subscriptions once the call is finished.
func cancelSubscriptions() async {
    await state.callEventsTask?.cancel()
    await state.chatEventTask?.cancel()
    await state.setCallEventTask(nil)
    await state.setChatEventTask(nil)
}
```

#### Initiating a voice call

```swift
func startCall() {
    Task {
        do {
            let callRequest = CallRequest(
                languageFromId: selectedLanguageFrom,
                languageToId: selectedLanguageTo,
                serviceTypeId: selectedServiceType,
                genderId: selectedGender,
                isVideo: false,
                data: [AdditionalField(key: "CustomKey", value: "CustomValue")],
                fieldData: fields
            )
            await subscribeOnCallEvents()
            await subscribeOnChatEvents()
            let call = try await state.boostlingo.makeVoiceCall(callRequest: callRequest)
            await state.setCall(call)
            callState = .calling
        } catch {
            callState = .noCall
            await showAlert(error.localizedDescription)
            await cancelSubscriptions()
        }
    }
}
```

#### Initiating a video call

You don't have to check the camera permission, the sdk will do it by itself. But you will need to provide `TVIVideoView` container for the remote and local video tracks.

```swift
func startCall() {
    Task {
        do {
            let callRequest = CallRequest(
                languageFromId: selectedLanguageFrom,
                languageToId: selectedLanguageTo,
                serviceTypeId: selectedServiceType,
                genderId: selectedGender,
                isVideo: true,
                data: [AdditionalField(key: "CustomKey", value: "CustomValue")],
                fieldData: fields
            )
            await subscribeOnCallEvents()
            await subscribeOnChatEvents()
            let call = try await state.boostlingo.makeVideoCall(
                callRequest: await callRequest,
                localVideoView: localView
            )
            await state.setCall(call)
            callState = .calling
        } catch {
            callState = .noCall
            await showAlert(error.localizedDescription)
            await cancelSubscriptions()
        }
    }
}
```

Later you will need to add a `TVIVideoView` as a renderer for remote participants when they join.

```swift
case .participantConnected(let participant, call: let call):
    print("callParticipantConnected")
    switch participant.participantType {
    case .interpreter:
        if let renderer = await state.removeView {
            await state.call?.addRenderer(
                for: participant.identity,
                renderer: renderer
            )
        }
    case .thirdParty:
        if let renderer = await state.thirdPartyParticipantView {
            await state.call?.addRenderer(
                for: participant.identity,
                renderer: renderer
            )
        }
    default:
        break
    }
```

#### Sending a chat message

```swift
func sendTestMessage() {
    Task {
        do {
            _ = try await state.boostlingo.sendChatMessage(text: "Test")
            await showAlert("Message sent")
        } catch {
            await showAlert(error.localizedDescription)
        }
    }
}
```

### Geting profile image URL

Getting requestor profile image url.

```swift
let url = try await boostlingo.getProfile()?.imageInfo?.url(size: 64)
```

Getting a participant profile image url from _BLCall_.

```swift
// Get the interpreter profile image URL
let url = await call?.participants.first?.imageInfo?.url(size: nil)
```

## More Documentation

You can find more documentation and useful information below:

* [Quickstart](https://github.com/boostlingo/boostlingo-ios/tree/master)
* [Doc](https://github.com/boostlingo/boostlingo-ios/tree/master)

