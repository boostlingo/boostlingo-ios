//
//  VoiceCallViewController.swift
//  BoostlingoQuickstart
//
//  Created by Denis Kornev on 1/23/20.
//  Copyright © 2022 Boostlingo. All rights reserved.
//

import Foundation
import Boostlingo
import UIKit

class VoiceCallViewController: UIViewController, BLCallDelegate, BLChatDelegate {
    
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
                self.lblCallStatus.isEnabled = false
                self.swMute.isEnabled = false
                self.swSpeaker.isEnabled = false
                self.btnHangUp.isEnabled = true
                self.lblCallStatus.text = "No active call"
            case .calling:
                self.lblCallStatus.isEnabled = false
                self.swMute.isEnabled = false
                self.swSpeaker.isEnabled = false
                self.btnHangUp.isEnabled = true
                self.lblCallStatus.text = "Calling"
            case .inprogress(let interpreterName):
                self.lblCallStatus.isEnabled = false
                self.swMute.isEnabled = true
                self.swSpeaker.isEnabled = true
                self.btnHangUp.isEnabled = true
                self.lblCallStatus.text = interpreterName == nil ? "Call in progress" : "Call in progress with \(interpreterName!)"
            }
        }
    }
    
    // MARK: - Fields
    weak var delegate: ViewControllerDelegate?
    var callRequest: CallRequest?
    var boostlingo: BoostlingoSDK?
    private var callId: Int?
    private var call: BLVoiceCall?
    
    // MARK: - Outlets
    @IBOutlet weak var lblCallStatus: UILabel!
    @IBOutlet weak var swSpeaker: UISwitch!
    @IBOutlet weak var swMute: UISwitch!
    @IBOutlet weak var btnHangUp: UIButton!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        boostlingo!.chatDelegate = self
        boostlingo!.makeVoiceCall(callRequest: callRequest!, delegate: self) { [weak self] call, error in
            guard let self else { return }

            if let error {
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
    
    override func viewDidDisappear(_ animated: Bool) {
        delegate = nil
        boostlingo = nil
        call = nil
    }
    
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
    
    // MARK: - BLChatDelegate
    func chatConnected() {
        
    }
    
    func chatDisconnected() {
        
    }
    
    func chatMessageRecieved(message: ChatMessage) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Chat Message Recieved", message: message.text, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - Actions
    @IBAction func btnSendMessageTouchUpInside(_ sender: Any) {
        boostlingo!.sendChatMessage(text: "Test") { [weak self] message, error in
            guard let self else { return }

            if let error {
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
    
    @IBAction func btnHangUpTouchUpInside(_ sender: Any) {
        state = .nocall
        boostlingo!.hangUp() { [weak self] error in
            guard let self else { return }

            if let error {
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
}
