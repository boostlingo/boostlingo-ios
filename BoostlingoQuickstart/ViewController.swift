//
//  ViewController.swift
//  BoostlingoQuickstart
//
//  Created by Denis Kornev on 7/21/22.
//  Copyright © 2022 Boostlingo. All rights reserved.
//

import UIKit
import Boostlingo
import AVFoundation

protocol ViewControllerDelegate : AnyObject {
    
    var callId: Int? { get set }
    func update(_ item: TableViewItem)
}

class ViewController: UIViewController, ViewControllerDelegate {
    
    private enum State {
        
        case notAuthenticated
        case loading
        case authenticated
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
                self.tfRegion.isEnabled = false
                self.btnRegion.isEnabled = true
                self.btnSignIn.isEnabled = true
                self.tfToken.isEnabled = false
                self.tfLanguageFrom.isEnabled = false
                self.btnLanguageFrom.isEnabled = false
                self.tfLanguageTo.isEnabled = false
                self.btnLanguageTo.isEnabled = false
                self.tfServiceType.isEnabled = false
                self.btnServiceType.isEnabled = false
                self.tfGender.isEnabled = false
                self.btnGender.isEnabled = false
                self.btnCall.isEnabled = false
                self.btnVideoCall.isEnabled = false
                self.btnLastCallDetails.isEnabled = false
            case .loading:
                self.tfRegion.isEnabled = false
                self.btnRegion.isEnabled = false
                self.btnSignIn.isEnabled = false
                self.tfToken.isEnabled = false
                self.tfLanguageFrom.isEnabled = false
                self.btnLanguageFrom.isEnabled = false
                self.tfLanguageTo.isEnabled = false
                self.btnLanguageTo.isEnabled = false
                self.tfServiceType.isEnabled = false
                self.btnServiceType.isEnabled = false
                self.tfGender.isEnabled = false
                self.btnGender.isEnabled = false
                self.btnCall.isEnabled = false
                self.btnVideoCall.isEnabled = false
                self.btnLastCallDetails.isEnabled = false
            case .authenticated:
                self.tfRegion.isEnabled = false
                self.btnRegion.isEnabled = false
                self.btnSignIn.isEnabled = false
                self.tfToken.isEnabled = false
                self.tfLanguageFrom.isEnabled = false
                self.btnLanguageFrom.isEnabled = true
                self.tfLanguageTo.isEnabled = false
                self.btnLanguageTo.isEnabled = true
                self.tfServiceType.isEnabled = false
                self.btnServiceType.isEnabled = true
                self.tfGender.isEnabled = false
                self.btnGender.isEnabled = true
                self.btnCall.isEnabled = true
                self.btnVideoCall.isEnabled = true
                self.btnLastCallDetails.isEnabled = true
            }
        }
    }
    
    
    // MARK: - Fields
    var callId: Int?
    private var boostlingo: BoostlingoSDK?
    private var regions: [String] = []
    private var selectedRegion: String?
    private var languages: [Language]?
    private var selectedLanguageFrom: Int?
    private var selectedLanguageTo: Int?
    private var serviceTypes: [ServiceType]?
    private var selectedServiceType: Int?
    private var genders: [Gender]?
    private var selectedGender: Int?
    private var call: BLCall?
    
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
    @IBOutlet weak var btnLastCallDetails: UIButton!
    @IBOutlet weak var btnVideoCall: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        regions = BoostlingoSDK.getRegions()
        selectedRegion = regions.first(where: { region -> Bool in
            return region == "qa"
        })
        self.tfToken.text = self.token
        state = .notAuthenticated
        print("Boostlingo SDK version: \(BoostlingoSDK.getVersion())")
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
    
    // MARK: - Actions
    @IBAction func btnSignInTouchUpInside(_ sender: Any) {
        state = .loading
        // For production builds use BLNullLogger() or your custom logger
        self.boostlingo = BoostlingoSDK(authToken: self.token, region: self.selectedRegion!, logger: BLPrintLogger())
        self.boostlingo!.initialize() { [weak self] error in
            guard let self = self else {
                return
            }
            
            guard error == nil else {
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
                return
            }
            
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
                let callRequest = CallRequest(
                    languageFromId: self.selectedLanguageFrom!,
                    languageToId: self.selectedLanguageTo!,
                    serviceTypeId: self.selectedServiceType!,
                    genderId: self.selectedGender,
                    isVideo: false,
                    data: [
                        AdditionalField(
                            key: "CustomKey",
                            value: "CustomValue"
                        )
                    ]
                )
                self.boostlingo?.validateCallReq(callReq: callRequest) { [weak self] error in
                    guard let self = self else { return }

                    DispatchQueue.main.async {
                        if let error = error {
                            self.state = .authenticated
                            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                            self.present(alert, animated: true)
                            return
                        } else {
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let controller = storyboard.instantiateViewController(withIdentifier: "VoiceCallViewController") as! VoiceCallViewController
                            controller.boostlingo = self.boostlingo
                            controller.callRequest = callRequest
                            controller.delegate = self
                            self.navigationController?.pushViewController(controller, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func btnLastCallDetailsTouchUpInside(_ sender: Any) {
        if let callId = self.callId {
            state = .loading
            self.boostlingo!.getCallDetails(callId: callId) { [weak self] (callDetails, error) in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if error == nil {
                        self.state = .authenticated
                        let alert = UIAlertController(title: "Info", message: "Call duration: \(String(describing: callDetails?.duration)) sec, CallId: \(callDetails?.callId ?? 0)",preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                    }
                    else {
                        self.state = .authenticated
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
            }
        }
    }
    
    @IBAction func BtnVideoCallTouchUpInside(_ sender: Any) {
        let callRequest = CallRequest(
            languageFromId: self.selectedLanguageFrom!,
            languageToId: self.selectedLanguageTo!,
            serviceTypeId: self.selectedServiceType!,
            genderId: self.selectedGender,
            isVideo: true,
            data: [
                AdditionalField(
                    key: "CustomKey",
                    value: "CustomValue"
                )
            ]
        )
        self.boostlingo?.validateCallReq(callReq: callRequest) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.state = .authenticated
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            } else {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "VideoCallViewController") as! VideoCallViewController
                controller.boostlingo = self.boostlingo
                controller.callRequest = callRequest
                controller.delegate = self
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
}

