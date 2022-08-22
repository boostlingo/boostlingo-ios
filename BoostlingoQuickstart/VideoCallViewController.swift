//
//  VideoCallViewController.swift
//  BoostlingoQuickstart
//
//  Created by Denis Kornev on 7/21/22.
//  Copyright © 2022 Boostlingo. All rights reserved.
//

import Foundation
import UIKit
import TwilioVideo
import Boostlingo

class VideoCallViewController: UIViewController, BLCallDelegate, BLChatDelegate {
    
    private enum State {
        
          case nocall
          case calling
          case inprogress(interpreterName: String?)
    }
    
    // MARK: - View State
    private var state: State = .nocall {
        didSet {
            switch state {
            case .nocall:
                btnFlip.isEnabled = false
                btnHangUp.isEnabled = true
                btnMute.isEnabled = false
                btnDialThirdParty.isEnabled = false
                btnHangUpThirdParty.isEnabled = false
                btnMuteThirdParty.isEnabled = false
                btnConfirmThirdParty.isEnabled = false
                lblCallStatus.text = "No active call"
            case .calling:
                btnFlip.isEnabled = false
                btnHangUp.isEnabled = true
                btnMute.isEnabled = false
                btnDialThirdParty.isEnabled = false
                btnHangUpThirdParty.isEnabled = false
                btnMuteThirdParty.isEnabled = false
                btnConfirmThirdParty.isEnabled = false
                lblCallStatus.text = "Calling"
            case .inprogress(let interpreterName):
                btnFlip.isEnabled = true
                btnHangUp.isEnabled = true
                btnMute.isEnabled = true
                btnDialThirdParty.isEnabled = true
                btnHangUpThirdParty.isEnabled = true
                btnMuteThirdParty.isEnabled = true
                btnConfirmThirdParty.isEnabled = true
                lblCallStatus.text = interpreterName == nil ? "Call in progress" : "Call in progress with \(interpreterName!)"
            }
        }
    }
    
    // MARK: - Fields
    weak var delegate: ViewControllerDelegate?
    var callRequest: CallRequest?
    var boostlingo: BoostlingoSDK?
    private var callId: Int?
    private var call: BLVideoCall?
    
    // MARK: - Outlets
    @IBOutlet weak var lblCallStatus: UILabel!
    @IBOutlet weak var vRemoteVideo: VideoView!
    @IBOutlet weak var vLocalVideo: VideoView!
    @IBOutlet weak var btnHangUp: UIButton!
    @IBOutlet weak var btnFlip: UIButton!
    @IBOutlet weak var btnMute: UIButton!
    @IBOutlet weak var btnConfirmThirdParty: UIButton!
    @IBOutlet weak var btnMuteThirdParty: UIButton!
    @IBOutlet weak var btnHangUpThirdParty: UIButton!
    @IBOutlet weak var btnDialThirdParty: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        vRemoteVideo.contentMode = .scaleAspectFit
        vLocalVideo.contentMode = .scaleAspectFit
        boostlingo!.chatDelegate = self
        boostlingo!.makeVideoCall(callRequest: callRequest!, localVideoView: vLocalVideo, delegate: self) { [weak self] call, error in
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
                
                self.call = call
                self.state = .calling
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        delegate = nil
        boostlingo = nil
        call = nil
    }
    
    // MARK: - BLCallDelegate
    func callDidConnect(_ call: BLCall, participants: [BLParticipant]) {
        print("callDidConnect")
        DispatchQueue.main.async {
            self.call = call as? BLVideoCall
            self.callId = self.call?.callId
            self.delegate?.callId = self.callId
            if call.isMuted {
                self.btnMute.setTitle("Muted", for: .normal)
            } else {
                self.btnMute.setTitle("Mute", for: .normal)
            }
            self.state = .inprogress(interpreterName: self.call?.interlocutorInfo?.requiredName)
            
            if let firstParticipant = participants.first {
                self.call?.addRenderer(for: firstParticipant.identity, renderer: self.vRemoteVideo)
            }
            
            print("Participants: \(participants.count)")
            for p in participants {
                self.printParticipant(p)
            }
        }
    }
    
    func callDidDisconnect(_ error: Error?) {
        print("callDidDisconnect")
        DispatchQueue.main.async {
            self.call = nil
            self.state = .nocall
            let title = error != nil ? "Error" : "Info"
            let message = error != nil ? "Call did disconnect with error: \(error!.localizedDescription)" : "Call did disconnect"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self]  (alert: UIAlertAction!) in
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
        print("callParticipantConnected")
        DispatchQueue.main.async {
            print("Participants: \(call.participants.count)")
            self.printParticipant(participant)
            
            if let firstParticipant = call.participants.first {
                self.call?.addRenderer(for: firstParticipant.identity, renderer: self.vRemoteVideo)
            }
        }
    }
    
    func callParticipantUpdated(_ participant: BLParticipant, call: BLCall) {
        print("callParticipantUpdated")
        DispatchQueue.main.async {
            print("Participants: \(call.participants.count)")
            self.printParticipant(participant)
        }
    }
    
    func callParticipantDisconnected(_ participant: BLParticipant, call: BLCall) {
        print("callParticipantDisconnected")
        DispatchQueue.main.async {
            print("Participants: \(call.participants.count)")
            self.printParticipant(participant)
        }
    }
    
    private func printParticipant(_ participant: BLParticipant) {
        print(
            "userAccountId: \(String(describing: participant.userAccountId)), thirdPartyParticipantId: \(String(describing: participant.thirdPartyParticipantId)), identity: \(participant.identity), isAudioEnabled: \(participant.isAudioEnabled), isVideoEnabled: \(participant.isVideoEnabled), muteActionIsEnabled: \(participant.muteActionIsEnabled), removeActionIsEnabled: \(participant.removeActionIsEnabled), requiredName: \(participant.requiredName), participantType: \(participant.participantType), rating: \(String(describing: participant.rating)), companyName: \(String(describing: participant.companyName)), state: \(participant.state), hash: \(participant.hashValue)"
        )
    }
    
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
    
    // MARK: - Actions
    @IBAction func btnPrivacyTouchUpInside(_ sender: Any) {
        if let call = call {
            call.isVideoEnabled = !call.isVideoEnabled
        }
        // TODO: Show you privacy screen here
//        boostlingo!.getProfile() { profile, error in
//            // Get the requestor profile URL
//            let url = profile?.imageInfo?.url(size: 64)
//        }
    }
        
    @IBAction func btnSendMessageTouchUpInside(_ sender: Any) {
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
    }
    
    @IBAction func btnHangUpTouchUpInside(_ sender: Any) {
        state = .nocall
        boostlingo!.hangUp() { [weak self] error in
            guard let self = self else { return }
          
            DispatchQueue.main.async {
                if let error = error {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] (alert: UIAlertAction!) in
                    guard let self = self else {
                        return
                    }
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true)
                return
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    @IBAction func btnFlipTouchUpInside(_ sender: Any) {
        if let call = call {
            call.flipCamera()
        }
    }
    
    @IBAction func btnMuteTouchUpInside(_ sender: Any) {
        if let call = call {
            call.isMuted = !call.isMuted
            if call.isMuted {
                btnMute.setTitle("Muted", for: .normal)
            } else {
                btnMute.setTitle("Mute", for: .normal)
            }
        }
    }
    
    @IBAction func btnDialThirdPartyTouchUpInside(_ sender: Any) {
        if let call = call {
            call.dialThirdParty(phone: "18004444444") { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                        return
                    } else {
                        let alert = UIAlertController(title: "Success", message: "dialThirdParty", preferredStyle: .alert)
                         alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                         self.present(alert, animated: true)
                         return
                    }
                }
            }
        }
    }
    
    @IBAction func btnHangUpThirdPartyTouchUpInside(_ sender: Any) {
        if let call = call, let participant = call.participants.first(where: { $0.participantType == .thirdParty }) {
            call.hangupThirdPartyParticipant(identity: participant.identity) { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                        return
                    } else {
                        let alert = UIAlertController(title: "Success", message: "hangupThirdPartyParticipant", preferredStyle: .alert)
                         alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                         self.present(alert, animated: true)
                         return
                    }
                }
            }
        }
    }
    
    @IBAction func btnMuteThirdPartyTouchUpInside(_ sender: Any) {
        if let call = call, let participant = call.participants.first(where: { $0.participantType == .thirdParty }) {
            call.muteThirdPartyParticipant(identity: participant.identity, mute: participant.isAudioEnabled) { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                        return
                    } else {
                        let alert = UIAlertController(title: "Success", message: "muteThirdPartyParticipant", preferredStyle: .alert)
                         alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                         self.present(alert, animated: true)
                         return
                    }
                }
            }
        }
    }
    
    @IBAction func btnConfirmThirdPartyTouchUpInside(_ sender: Any) {
        if let call = call, let participant = call.participants.first(where: { $0.state == .confirmation }) {
            call.confirmThirdPartyParticipant(identity: participant.identity, confirm: true) { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                        return
                    } else {
                        let alert = UIAlertController(title: "Success", message: "confirmThirdPartyParticipant", preferredStyle: .alert)
                         alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                         self.present(alert, animated: true)
                         return
                    }
                }
            }
        }
    }
}
