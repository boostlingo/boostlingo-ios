# Boostlingo iOS

The Boostlingo iOS swift library enables developers to embed the Boostlingo caller directly into their own applications. This can then be used for placing calls in the Boostlingo platform.

## Getting Started

In order to place calls in Boostlingo, you must have a requestor account. You can then embed Boostlingo iOS into your application, request a Boostlingo API token from your server, and start making calls.

## Installation

The Boostlingo iOS framework can be installed using [Cartfile](https://github.com/Carthage/Carthage).
You can add Boostlingo SDK for iOS by adding the following line to your Cartfile:

```sh
github "boostlingo/boostlingo-ios"
```

Then run `carthage bootstrap` (or `carthage update --cache-builds` if you are updating your SDKs).

On your application targets’ “General” settings tab, in the “Linked Frameworks and Libraries” section, drag and drop each framework you want to use from the Carthage/Build folder on disk. For Boostlingo SDK you will need to link following frameworks:

```sh
Alamofire.framework, Moya.framework, Result.framework, TwilioVoice.framework, Boostlingo.framework
```
> NOTE: At this time, Carthage does not provide a way to build only specific repository submodules. All submodules and their dependencies will be built with the above command. However, you don't need to copy frameworks you aren't using into your project. Due to that first build of Carthage dependencies may take long time.

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

## Usage

These steps will guide you through the basic process of placing calls through Boostlingo.

### Request Boostlingo authentication token

First step is to obtain a boostlingo authentication token from your server.  Never store an API token or username/password in your front end/mobile code.  Your server should be the one that logs the user in, obtains the authentication token, and passes it back down to the web application.

### Obtain Boostlingo authentication token via API endpoint

```
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
`token` is what will be needed by the boostlingo-js library

```json
{
"userAccountId": "<integer>",
"role": "<string>",
"token": "<string>",
"companyAccountId": "<integer>"
}
```

### Quickstart

This is a working example that will demonstrate how to Boostlingo calls.
Now let’s go to the Quickstart folder. Then run `carthage update --cache-builds` to download and build dependencies.
Update the placeholder of TOKEN with the token you got from the API.

```swift
private let token = <TOKEN>
```

### Create instance of Boostlingo class and load dictionaries

We recommend you do this only once. The Boostlingo library will cache specific data and create instances of classes that do not need to be refreshed very frequently. The next step is typically to pull down the call dictionaries. Whether you expose these directly or are just mapping languages and service types with your internal types, loading these lists will almost definitely be required. In this example we populate a series of select dropdown inputs.

```swift
self.boostlingo = Boostlingo(authToken: self.token, region: self.selectedRegion!, logLevel: BLLogLevel.error)
self.boostlingo!.delegate = self
self.boostlingo!.getCallDictionaries() { [weak self] (callDictionaries, error) in
    guard let self = self else {
    return
    }

    if error == nil {
        self.languages = callDictionaries?.languages
        self.serviceTypes = callDictionaries?.serviceTypes
        self.genders = callDictionaries?.genders
        self.selectedLanguageFrom = self.languages?.first(where: { item -> Bool in return item.id == 4 })?.id
        self.selectedLanguageTo = self.languages?.first(where: { item -> Bool in return item.id == 1 })?.id
        self.selectedServiceType = self.serviceTypes?.first(where: { item -> Bool in return item.id == 1 })?.id
        self.selectedGender = self.genders?.first?.id
        self.updateUI()
        self.state = .authenticated
    }
    else {
        self.state = .notAuthenticated
        let alert = UIAlertController(title: "Error", message: error!.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
}
```

### Implement BLCallDelegate

```swift
// MARK: - BLCallDelegate
func callDidConnect(_ call: BLCall) {
    self.call = call
    swMute.isOn = call.isMuted
    state = .inprogress(interpreterName: self.call?.interlocutorInfo?.requiredName)
}

func callDidDisconnect(_ error: Error?) {
    self.call = nil
    state = .authenticated
    let title = error != nil ? "Error" : "Info"
    let message = error != nil ? "Call did disconnect with error: \(error!.localizedDescription)" : "Call did disconnect"
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    self.present(alert, animated: true)
}

func callDidFailToConnect(_ error: Error?) {
    self.call = nil
    state = .authenticated
    let title = error != nil ? "Error" : "Info"
    let message = error != nil ? "Call did fail to connect with error: \(error!.localizedDescription)" : "Call did fail to connect"
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    self.present(alert, animated: true)
}
```

### Placing a call

Before placing a call you will need to check record permission:

```swift
private func checkRecordPermission(completion: @escaping (_ permissionGranted: Bool) -> Void) {
    let permissionStatus: AVAudioSession.RecordPermission = AVAudioSession.sharedInstance().recordPermission

    switch permissionStatus {
    case AVAudioSessionRecordPermission.granted:
        // Record permission already granted.
        completion(true)
        break
    case AVAudioSessionRecordPermission.denied:
        // Record permission denied.
        completion(false)
        break
    case AVAudioSessionRecordPermission.undetermined:
        // Requesting record permission.
        // Optional: pop up app dialog to let the users know if they want to request.
        AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
            completion(granted)
        })
        break
    default:
        completion(false)
        break
    }
}
```

```swift
self.state = .loading
self.boostlingo!.makeCall(callRequest: CallRequest(languageFromId: self.selectedLanguageFrom!, languageToId: self.selectedLanguageTo!, serviceTypeId: self.selectedServiceType!, genderId: self.selectedGender)) { [weak self] error in
    guard let self = self else {
        return
    }

    if let error = error {
        self.state = .authenticated
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
        return
    }

    self.state = .calling
}
```

## More Documentation

You can find more documentation and useful information below:

* [Quickstart](https://github.com/boostlingo/boostlingo-ios/tree/master/Quickstart)
* [Doc](http://connect.boostlingo.com/sdk/boostlingo-ios/0.1.0/docs/index.html)


