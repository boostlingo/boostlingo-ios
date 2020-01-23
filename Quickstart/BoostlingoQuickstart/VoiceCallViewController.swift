//
//  VoiceCallViewController.swift
//  BoostlingoQuickstart
//
//  Created by Denis Kornev on 1/23/20.
//  Copyright © 2020 Boostlingo. All rights reserved.
//

import Foundation
import Boostlingo
import UIKit

class VoiceCallViewController: UIViewController, BLCallDelegate {
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
    var boostlingo: Boostlingo?
    private var callId: Int?
    private var call: BLCall?
    
    // MARK: - Outlets
    @IBOutlet weak var lblCallStatus: UILabel!
    @IBOutlet weak var swSpeaker: UISwitch!
    @IBOutlet weak var swMute: UISwitch!
    @IBOutlet weak var btnHangUp: UIButton!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
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
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        delegate = nil
        boostlingo = nil
    }
    
    // MARK: - BLCallDelegate
    func callDidConnect(_ call: BLCall) {
        DispatchQueue.main.async {
            self.call = call
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
    
    // MARK: - Actions
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
