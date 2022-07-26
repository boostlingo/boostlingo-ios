# Boostlingo iOS

The Boostlingo iOS Swift library enables developers to embed the Boostlingo caller directly into their own applications. This can then be used for placing calls in the Boostlingo platform.

## Getting Started

In order to place calls in Boostlingo, you must have a requestor account. You can then embed Boostlingo iOS into your application, request a Boostlingo API token from your server, and start making calls.

## Installation

### CocoaPods

It's easy to install the framework if you manage your dependencies using [CocoaPods](https://cocoapods.org/). Simply add the following to your Podfile:

```sh
source 'https://github.com/cocoapods/specs'

target 'TARGET_NAME' do
  use_frameworks!

  pod 'BoostlingoSDK', '1.0.0'
end
```

Then run `pod install --verbose` to install the dependencies to your project.

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

This is a working example that will demonstrate how to Boostlingo calls.
Now let's go to the Quickstart folder. Then run `pod install --verbose` to download and build dependencies.
Update the placeholder of TOKEN with the token you got from the API.

```swift
private let token = <TOKEN>
```

### Create instance of Boostlingo class and load dictionaries

We recommend you do this only once. The Boostlingo library will cache specific data and create instances of classes that do not need to be refreshed very frequently. The next step is typically to pull down the call dictionaries. Whether you expose these directly or are just mapping languages and service types with your internal types, loading these lists will almost definitely be required. In this example we populate a series of select dropdown inputs.

```swift
// For debug builds use BLPrintLogger() or your custom logger
self.boostlingo = BoostlingoSDK(authToken: self.token, region: self.selectedRegion!, logger: BLNullLogger())
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
        let message: String
        switch error! {
        case BLError.apiCall(_, let statusCode):
            message = "\(error!.localizedDescription), statusCode: \(statusCode)"
            break
        default:
            message = error!.localizedDescription
            break
        }
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
}
```

### Implement BLCallDelegate

```swift
// MARK: - BLCallDelegate
    func callDidConnect(_ call: BLCall, participants: [BLParticipant]) {
        DispatchQueue.main.async {
            self.call = call as? BLVoiceCall
            self.callId = self.call?.callId
            self.delegate?.callId = self.callId
            self.swMute.isOn = call.isMuted
            self.state = .inprogress(interpreterName: self.call?.interlocutorInfo?.requiredName)
        }
    }
    
    func callDidDisconnect(_ error: Error?) {
        DispatchQueue.main.async {
            self.call = nil
            self.state = .nocall
            let title = error != nil ? "Error" : "Info"
            let message = error != nil ? "Call did disconnect with error: \(error!.localizedDescription)" : "Call did disconnect"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] (alert: UIAlertAction!) in
                guard let self = self else {
                    return
                }
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true)
        }
    }
    
    func callDidFailToConnect(_ error: Error?) {
        DispatchQueue.main.async {
            self.call = nil
            self.state = .nocall
            let title = error != nil ? "Error" : "Info"
            let message = error != nil ? "Call did fail to connect with error: \(error!.localizedDescription)" : "Call did fail to connect"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] (alert: UIAlertAction!) in
                guard let self = self else {
                    return
                }
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true)
        }
    }
    
    func callParticipantConnected(_ participant: BLParticipant, call: BLCall) {
        print("Participants: \(call.participants.count)")
        for p in call.participants {
            printParticipant(p)
        }
    }
    
    func callParticipantUpdated(_ participant: BLParticipant, call: BLCall) {
        print("Participants: \(call.participants.count)")
        for p in call.participants {
            printParticipant(p)
        }
    }
    
    func callParticipantDisconnected(_ participant: BLParticipant, call: BLCall) {
        print("Participants: \(call.participants.count)")
        for p in call.participants {
            printParticipant(p)
        }
    }
    
    private func printParticipant(_ participant: BLParticipant) {
        print("identity: \(participant.identity), isAudioEnabled: \(participant.isAudioEnabled), isVideoEnabled: \(participant.isVideoEnabled), muteActionIsEnabled: \(participant.muteActionIsEnabled), removeActionIsEnabled: \(participant.removeActionIsEnabled), requiredName: \(participant.requiredName), participantType: \(participant.participantType), rating: \(String(describing: participant.rating)), companyName: \(String(describing: participant.companyName)), state: \(participant.state)")
    }
```

### Placing a voice call

Before placing a call you will need to check record permission:

```swift
private func checkRecordPermission(completion: @escaping (_ permissionGranted: Bool) -> Void) {
    let permissionStatus: AVAudioSession.RecordPermission = AVAudioSession.sharedInstance().recordPermission

    switch permissionStatus {
    case .granted:
        // Record permission already granted.
        completion(true)
        break
    case .denied:
        // Record permission denied.
        completion(false)
        break
    case .undetermined:
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
self.boostlingo!.delegate = self
self.boostlingo!.makeVoiceCall(callRequest: callRequest!) { [weak self] error in
    guard let self = self else {
        return
    }

    DispatchQueue.main.async {
        if let error = error {
            self.state = .nocall
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self]  (alert: UIAlertAction!) in
                guard let self = self else {
                    return
                }
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true)
            return
        }

        self.state = .calling
    }
}
```

### Placing a video call

You don't have to check the camera permission, the sdk will do it by itself. But you will need to provide TVIVideoView container for the remote and local video tracks.

```swift
vRemoteVideo.contentMode = .scaleAspectFit
vLocalVideo.contentMode = .scaleAspectFit
boostlingo!.makeVideoCall(callRequest: callRequest!, localVideoView: vLocalVideo, delegate: self)  { [weak self] error in
    guard let self = self else {
        return
    }
    
    DispatchQueue.main.async {
        if let error = error {
            self.state = .nocall
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self]  (alert: UIAlertAction!) in
                guard let self = self else {
                    return
                }
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true)
            return
        }
        
        self.state = .calling
    }
}

// Adding a renderer for a participant
call.addRenderer(for: participant.identity, renderer: self.vRemoteVideo)
```

### Using the chat functionality

Subscribe for the chat related callback using _BLChatDelegate_.

```swift
boostlingo!.chatDelegate = self
```

```swift
// MARK: - BLChatDelegate
func chatConnected() {
    
}

func chatDisconnected() {
    
}

func chatMessageRecieved(message: ChatMessage) {
    let alert = UIAlertController(title: "Chat Message Recieved", message: message.text, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    present(alert, animated: true)
}
```

Sending messages.

```swift
boostlingo!.sendChatMessage(text: "Test") { [weak self] message, error in
    guard let self = self else { return }
    
    DispatchQueue.main.async {
        if let error = error {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        } else {
            let alert = UIAlertController(title: "Success", message: "Message sent", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
        }
    }
}
```

### Geting profile image URL

Getting requestor profile image url.

```swift
boostlingo!.getProfile() { profile, error in
    // Get the requestor profile URL
    let url = profile?.imageInfo?.url(size: 64)
}
```

Getting a participant profile image url from _BLCall_.

```swift
// Get the interpreter profile image URL
let url = call?.participants.first?.imageInfo?.url(size: nil)
```

## More Documentation

You can find more documentation and useful information below:

* [Quickstart](https://github.com/boostlingo/boostlingo-ios/tree/master)
* [Doc](http://connect.boostlingo.com/sdk/boostlingo-ios/1.0/docs/index.html)
