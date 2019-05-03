//
//  ViewController.swift
//  boostlingo-ios
//
//  Created by Denis Kornev on 18/04/2019.
//  Copyright © 2019 Boostlingo. All rights reserved.
//

import UIKit
import Boostlingo
import AVFoundation

protocol ViewControllerDelegate : AnyObject {
    func update(_ item: TableViewItem)
}

class ViewController: UIViewController, ViewControllerDelegate, BLCallDelegate {
    private enum State {
        case notAuthenticated
        case loading
        case authenticated
        case calling
        case inprogress(interpreterName: String?)
    }
    
    private enum TableViewType {
        case region
        case languageFrom
        case languageTo
        case serviceType
        case gender
    }
    
    private let token = <TOKEN>
    
    private var tableViewType: TableViewType?
    
    // MARK: - View State
    private var state: State = .notAuthenticated {
        didSet {
            switch state {
            case .notAuthenticated:
                tfRegion.isEnabled = false
                btnRegion.isEnabled = true
                btnSignIn.isEnabled = true
                tfToken.isEnabled = false
                tfLanguageFrom.isEnabled = false
                btnLanguageFrom.isEnabled = false
                tfLanguageTo.isEnabled = false
                btnLanguageTo.isEnabled = false
                tfServiceType.isEnabled = false
                btnServiceType.isEnabled = false
                tfGender.isEnabled = false
                btnGender.isEnabled = false
                btnCall.isEnabled = false
                lblCallStatus.isEnabled = false
                swMute.isEnabled = false
                swSpeaker.isEnabled = false
                btnHangUp.isEnabled = false
                lblCallStatus.text = "No active call"
            case .loading:
                tfRegion.isEnabled = false
                btnRegion.isEnabled = false
                btnSignIn.isEnabled = false
                tfToken.isEnabled = false
                tfLanguageFrom.isEnabled = false
                btnLanguageFrom.isEnabled = false
                tfLanguageTo.isEnabled = false
                btnLanguageTo.isEnabled = false
                tfServiceType.isEnabled = false
                btnServiceType.isEnabled = false
                tfGender.isEnabled = false
                btnGender.isEnabled = false
                btnCall.isEnabled = false
                lblCallStatus.isEnabled = false
                swMute.isEnabled = false
                swSpeaker.isEnabled = false
                btnHangUp.isEnabled = false
                lblCallStatus.text = "Loading"
            case .authenticated:
                tfRegion.isEnabled = false
                btnRegion.isEnabled = false
                btnSignIn.isEnabled = false
                tfToken.isEnabled = false
                tfLanguageFrom.isEnabled = false
                btnLanguageFrom.isEnabled = true
                tfLanguageTo.isEnabled = false
                btnLanguageTo.isEnabled = true
                tfServiceType.isEnabled = false
                btnServiceType.isEnabled = true
                tfGender.isEnabled = false
                btnGender.isEnabled = true
                btnCall.isEnabled = true
                lblCallStatus.isEnabled = false
                swMute.isEnabled = false
                swSpeaker.isEnabled = false
                btnHangUp.isEnabled = false
                lblCallStatus.text = "No active call"
            case .calling:
                tfRegion.isEnabled = false
                btnRegion.isEnabled = false
                btnSignIn.isEnabled = false
                tfToken.isEnabled = false
                tfLanguageFrom.isEnabled = false
                btnLanguageFrom.isEnabled = false
                tfLanguageTo.isEnabled = false
                btnLanguageTo.isEnabled = false
                tfServiceType.isEnabled = false
                btnServiceType.isEnabled = false
                tfGender.isEnabled = false
                btnGender.isEnabled = false
                btnCall.isEnabled = false
                lblCallStatus.isEnabled = false
                swMute.isEnabled = false
                swSpeaker.isEnabled = false
                btnHangUp.isEnabled = true
                lblCallStatus.text = "Calling"
            case .inprogress(let interpreterName):
                tfRegion.isEnabled = false
                btnRegion.isEnabled = false
                btnSignIn.isEnabled = false
                tfToken.isEnabled = false
                tfLanguageFrom.isEnabled = false
                btnLanguageFrom.isEnabled = false
                tfLanguageTo.isEnabled = false
                btnLanguageTo.isEnabled = false
                tfServiceType.isEnabled = false
                btnServiceType.isEnabled = false
                tfGender.isEnabled = false
                btnGender.isEnabled = false
                btnCall.isEnabled = false
                lblCallStatus.isEnabled = false
                swMute.isEnabled = true
                swSpeaker.isEnabled = true
                btnHangUp.isEnabled = true
                lblCallStatus.text = interpreterName == nil ? "Call in progress" : "Call in progress with \(interpreterName!)"
            }
        }
    }
    
    private var call: BLCall?
    
    // MAKR: - Fields
    private var boostlingo: Boostlingo?
    private var regions: [String] = []
    private var selectedRegion: String?
    private var languages: [Language]?
    private var selectedLanguageFrom: Int?
    private var selectedLanguageTo: Int?
    private var serviceTypes: [ServiceType]?
    private var selectedServiceType: Int?
    private var genders: [Gender]?
    private var selectedGender: Int?
    
    // MARK: - Outlets
    @IBOutlet weak var tfRegion: UITextField!
    @IBOutlet weak var btnRegion: UIButton!
    @IBOutlet weak var btnSignIn: UIButton!
    @IBOutlet weak var tfToken: UITextField!
    @IBOutlet weak var tfLanguageFrom: UITextField!
    @IBOutlet weak var btnLanguageFrom: UIButton!
    @IBOutlet weak var tfLanguageTo: UITextField!
    @IBOutlet weak var btnLanguageTo: UIButton!
    @IBOutlet weak var tfServiceType: UITextField!
    @IBOutlet weak var btnServiceType: UIButton!
    @IBOutlet weak var tfGender: UITextField!
    @IBOutlet weak var btnGender: UIButton!
    @IBOutlet weak var btnCall: UIButton!
    @IBOutlet weak var lblCallStatus: UILabel!
    @IBOutlet weak var swMute: UISwitch!
    @IBOutlet weak var swSpeaker: UISwitch!
    @IBOutlet weak var btnHangUp: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        regions = Boostlingo.getRegions()
        selectedRegion = regions.first(where: { region -> Bool in
            return region == "qa"
        })
        lblCallStatus.text = nil
        self.tfToken.text = self.token
        state = .notAuthenticated
        print("Boostlingo SDK version: \(Boostlingo.getVersion())")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateUI()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "Region":
            let controller = segue.destination as! TableViewController
            var data: [TableViewItem] = []
            for region in regions {
                data.append(TableViewItem(value: region, text: region))
            }
            controller.data = data
            controller.delegate = self
            tableViewType = .region
        case "LanguageFrom":
            let controller = segue.destination as! TableViewController
            var data: [TableViewItem] = []
            for language in languages! {
                data.append(TableViewItem(value: String(language.id), text: language.name))
            }
            controller.data = data
            controller.delegate = self
            tableViewType = .languageFrom
        case "LanguageTo":
            let controller = segue.destination as! TableViewController
            var data: [TableViewItem] = []
            for language in languages! {
                data.append(TableViewItem(value: String(language.id), text: language.name))
            }
            controller.data = data
            controller.delegate = self
            tableViewType = .languageTo
        case "ServiceType":
            let controller = segue.destination as! TableViewController
            var data: [TableViewItem] = []
            for serviceType in serviceTypes! {
                data.append(TableViewItem(value: String(serviceType.id), text: serviceType.name))
            }
            controller.data = data
            controller.delegate = self
            tableViewType = .serviceType
        case "Gender":
            let controller = segue.destination as! TableViewController
            var data: [TableViewItem] = []
            for gender in genders! {
                data.append(TableViewItem(value: String(gender.id), text: gender.name))
            }
            controller.data = data
            controller.delegate = self
            tableViewType = .gender
        case .none: break
        case .some(_): break
        }
    }
    
    func update(_ item: TableViewItem) {
        switch tableViewType {
        case .region?:
            selectedRegion = item.value
        case .languageFrom?:
            selectedLanguageFrom = Int(item.value)
        case .languageTo?:
            selectedLanguageTo = Int(item.value)
        case .serviceType?:
            selectedServiceType = Int(item.value)
        case .gender?:
            selectedGender = Int(item.value)
        default:
            break
        }
        updateUI()
        tableViewType = nil
    }
    
    private func updateUI() {
        tfRegion.text = selectedRegion
        tfLanguageFrom.text = languages?.first(where: { language -> Bool in
            return language.id == selectedLanguageFrom
        })?.name
        tfLanguageTo.text = languages?.first(where: { language -> Bool in
            return language.id == selectedLanguageTo
        })?.name
        tfServiceType.text = serviceTypes?.first(where: { serviceType -> Bool in
            return serviceType.id == selectedServiceType
        })?.name
        tfGender.text = genders?.first(where: { gender -> Bool in
            return gender.id == selectedGender
        })?.name
    }
    
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
    
    // MARK: - Actions
    @IBAction func btnSignInTouchUpInside(_ sender: Any) {
        state = .loading
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
    }
    
    @IBAction func btnCallTouchUpInside(_ sender: Any) {
        self.checkRecordPermission { (permissionGranted) in
            if !permissionGranted {
                let alertController: UIAlertController = UIAlertController(title: "Boostlingo Quick Start",
                                                                           message: "Microphone permission not granted",
                                                                           preferredStyle: .alert)
                
                let goToSettings: UIAlertAction = UIAlertAction(title: "Settings",
                                                                style: .default,
                                                                handler: { (action) in
                                                                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                              options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: false],
                                                                                              completionHandler: nil)
                })
                alertController.addAction(goToSettings)
                
                let cancel: UIAlertAction = UIAlertAction(title: "Cancel",
                                                          style: .cancel,
                                                          handler: { (action) in
                })
                alertController.addAction(cancel)
                
                self.present(alertController, animated: true, completion: nil)
            } else {
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
            }
        }
    }
    
    @IBAction func swMuteValueChanged(_ sender: Any) {
        if let call = call {
            call.isMuted = swMute.isOn
        }
    }
    
    @IBAction func swSpeakerValueChanged(_ sender: Any) {
        if call != nil {
            self.boostlingo!.toggleAudioRoute(toSpeaker: swSpeaker.isOn)
        }
    }
    
    @IBAction func btnHangUpTouchUpInside(_ sender: Any) {
        state = .loading
        boostlingo!.hangUp() { [weak self] error in
            guard let self = self else {
                return
            }
            
            if let error = error {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            }
            
            self.state = .authenticated
        }
    }
}

