//
//  VideoCallViewController.swift
//  BoostlingoQuickstart
//
//  Created by Denis Kornev on 1/21/20.
//  Copyright © 2020 Boostlingo. All rights reserved.
//

import Foundation
import Boostlingo
import UIKit
import TwilioVideo

class VideoCallViewController: UIViewController, BLCallDelegate, BLVideoDelegate, BLChatDelegate {
    
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
                self.btnFlip.isEnabled = false
                self.btnHangUp.isEnabled = true
                self.btnMute.isEnabled = false
                self.lblCallStatus.text = "No active call"
            case .calling:
                self.btnFlip.isEnabled = false
                self.btnHangUp.isEnabled = true
                self.btnMute.isEnabled = false
                self.lblCallStatus.text = "Calling"
            case .inprogress(let interpreterName):
                self.btnFlip.isEnabled = true
                self.btnHangUp.isEnabled = true
                self.btnMute.isEnabled = true
                self.lblCallStatus.text = interpreterName == nil ? "Call in progress" : "Call in progress with \(interpreterName!)"
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        vRemoteVideo.contentMode = .scaleAspectFit
        vLocalVideo.contentMode = .scaleAspectFit
        boostlingo!.chatDelegate = self
        self.boostlingo!.makeVideoCall(callRequest: callRequest!, remoteVideoView: vRemoteVideo, localVideoView: vLocalVideo, delegate: self, videoDelegate: self) { [weak self] call, error in
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
    func callDidConnect(_ call: BLCall) {
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
        }
    }
    
    func callDidDisconnect(_ error: Error?) {
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
    
    // MARK: - BLVideoDelegate
    func remoteAudioEnabled() {
        
    }
    
    func remoteAudioDisabled() {
        
    }
    
    func remoteVideoEnabled() {
        
    }
    
    func remoteVideoDisabled() {
        // TODO: Interpreter has disabled the video. Show you privacy screen here
        // Get the interpreter profile image URL
        // let url = call?.interlocutorInfo?.imageInfo?.url(size: nil)
    }
    
    func remoteAudioPublished() {
        
    }
    
    func remoteAudioUnpublished() {
        
    }
    
    func remoteVideoPublished() {
        
    }
    
    func remoteVideoUnpublished() {
        
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
}
