//
//  VoiceViewModel.swift
//  BoostlingoQuickstart
//
//  Created by Leonid Gorbarenko on 19.05.2025.
//  Copyright © 2025 Boostlingo LLC. All rights reserved.
//

import SwiftUI
import BoostlingoSDK

final class ViewControllerSendableDelegate: @unchecked Sendable {
    
    weak var delegate: ViewControllerDelegate?
}

actor VoiceCallState {
    
    var callId: Int?
    var callRequest: CallRequest
    var boostlingo: Boostlingo
    var call: BLVoiceCall?
    
    var callEventsTask: Task<Void, Never>?
    var chatEventTask: Task<Void, Never>?
    let navigationPath: Binding<[Screen]>
    
    init(
        callId: Int? = nil,
        callRequest: CallRequest,
        boostlingo: Boostlingo,
        call: BLVoiceCall? = nil,
        navigationPath: Binding<[Screen]>
    ) {
        self.callId = callId
        self.callRequest = callRequest
        self.boostlingo = boostlingo
        self.call = call
        self.navigationPath = navigationPath
    }
    
    func setCall(_ call: BLVoiceCall?) {
        self.call = call
    }
    
    func setCallId(_ callId: Int?) {
        self.callId = callId
    }
    
    func setCallEventTask(_ task: Task<Void, Never>?) {
        self.callEventsTask = task
    }
    
    func setChatEventTask(_ task: Task<Void, Never>?) {
        self.chatEventTask = task
    }
}

@MainActor
@Observable
final class VoiceCallViewModel: NSObject, Sendable {

    enum State {
        case noCall
        case calling
        case inProgress(interpreterName: String?)
    }

    @ObservationIgnored let delegate = ViewControllerSendableDelegate()
    @ObservationIgnored let state: VoiceCallState
    
    var callState: State = .noCall
    var isMuted = false
    var isSpeakerOn = false
    var alertMessage: String? = nil

    init(
        boostlingo: Boostlingo,
        callRequest: CallRequest,
        navigationPath: Binding<[Screen]>
    ) {
        self.state = VoiceCallState(
            callRequest: callRequest,
            boostlingo: boostlingo,
            navigationPath: navigationPath
        )
    }
    
    func startCall() {
        Task {
            do {
                await subscribeOnCallEvents()
                await subscribeOnChatEvents()
                try await state.setCall(
                    state.boostlingo.makeVoiceCall(callRequest: state.callRequest)
                )
                callState = .calling
            } catch {
                callState = .noCall
                await showAlert(error.localizedDescription)
            }
        }
    }

    func hangUp() {
        callState = .noCall
        Task {
            do {
                try await state.boostlingo.hangUp()
            } catch {
                await showAlert(error.localizedDescription)
            }
        }
    }

    func toggleMute(_ value: Bool) {
        Task {
            if let call = await state.call {
                await call.setIsMuted(value)
                isMuted = await call.getIsMuted()
            }
        }
    }

    func toggleSpeaker(_ value: Bool) {
        Task {
            isSpeakerOn = value
            await state.boostlingo.toggleAudioRoute(toSpeaker: value)
        }
    }

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

    private func showAlert(_ message: String) async {
        alertMessage = message
    }
    
    func dialThirdParty() {
        Task {
            do {
                try await state.call?.dialThirdParty(phone: "18004444444")
                await showAlert("dialThirdParty: success")
            } catch {
                await showAlert(error.localizedDescription)
            }
        }
    }

    func hangUpThirdParty() {
        Task {
            guard let participant = await state.call?.participants.first(where: { $0.participantType == .thirdParty })
            else { return }
            
            do {
                try await state.call?.hangupThirdPartyParticipant(
                    identity: participant.identity
                )
                await showAlert("hangupThirdPartyParticipant: success")
            } catch {
                await showAlert(error.localizedDescription)
            }
        }
    }

    func muteThirdParty() {
        Task {
            guard let participant = await state.call?.participants.first(where: { $0.participantType == .thirdParty }) else { return }
            do {
                try await state.call?.muteThirdPartyParticipant(
                    identity: participant.identity,
                    mute: participant.isAudioEnabled
                )
                await showAlert("muteThirdPartyParticipant: success")
            } catch {
                await showAlert(error.localizedDescription)
            }
        }
    }

    func confirmThirdParty() {
        Task {
            guard let participant = await state.call?.participants.first(where: { $0.state == .confirmation }) else { return }
            do {
                try await state.call?.confirmThirdPartyParticipant(
                    identity: participant.identity,
                    confirm: true
                )
                await showAlert("confirmThirdPartyParticipant:true: success")
            } catch {
                await showAlert(error.localizedDescription)
            }
        }
    }
    
    func declineThirdParty() {
        Task {
            guard let participant = await state.call?.participants.first(where: { $0.state == .confirmation }) else { return }
            do {
                try await state.call?.confirmThirdPartyParticipant(
                    identity: participant.identity,
                    confirm: false
                )
                await showAlert("confirmThirdPartyParticipant:false: success")
            } catch {
                await showAlert(error.localizedDescription)
            }
        }
    }
}

extension VoiceCallViewModel {
    
    func subscribeOnCallEvents() async {
        let callEventTask = Task {
            for await event in await state.boostlingo.callEventStream {
                guard !Task.isCancelled else { break }
                switch event {
                case .callDidConnect(let call, participants: _):
                    await state.setCall(call as? BLVoiceCall)
                    await state.setCallId(call.callId)
                    delegate.delegate?.callId = await state.callId
                    isMuted = await call.getIsMuted()
                    callState = .inProgress(
                        interpreterName: await state.call?.interlocutorInfo?.requiredName
                    )
                case .callDidDisconnect(let error):
                    await state.setCall(nil)
                    self.callState = .noCall
                    let msg = error != nil ? "Call did disconnect with error: \(error!.localizedDescription)" : "Call did disconnect"
                    await showAlert(msg)
                    state.navigationPath.wrappedValue.removeLast()
                    await cancelSubscriptions()
                case .callDidFailToConnect(let error):
                    await state.setCall(nil)
                    self.callState = .noCall
                    let msg = error != nil ? "Call failed to connect: \(error!.localizedDescription)" : "Call failed to connect"
                    await showAlert(msg)
                    state.navigationPath.wrappedValue.removeLast()
                    await cancelSubscriptions()
                case .participantConnected(let participant, call: let call):
                    print("callParticipantConnected")
                    print("Participants: \(await call.participants.count)")
                    printParticipant(participant)
                case .participantUpdated(let participant, call: let call):
                    print("callParticipantUpdated")
                    print("Participants: \(await call.participants.count)")
                    printParticipant(participant)
                case .participantDisconnected(let participant, call: let call):
                    print("callParticipantDisconnected")
                    print("Participants: \(await call.participants.count)")
                    printParticipant(participant)
                @unknown default: break
                }
            }
        }
        await state.setCallEventTask(callEventTask)
    }
    
    private func printParticipant(_ participant: BLParticipant) {
        print(
            "userAccountId: \(String(describing: participant.userAccountId)), thirdPartyParticipantId: \(String(describing: participant.thirdPartyParticipantId)), identity: \(participant.identity), isAudioEnabled: \(participant.isAudioEnabled), isVideoEnabled: \(participant.isVideoEnabled), muteActionIsEnabled: \(participant.muteActionIsEnabled), removeActionIsEnabled: \(participant.removeActionIsEnabled), requiredName: \(participant.requiredName), participantType: \(participant.participantType), rating: \(String(describing: participant.rating)), companyName: \(String(describing: participant.companyName)), state: \(participant.state), hash: \(participant.hashValue)"
        )
    }

    func subscribeOnChatEvents() async {
        let chatEventTask = Task {
            for await event in await state.boostlingo.chatEventStream {
                guard !Task.isCancelled else { break }
                switch event {
                case .chatConnected: break
                case .chatDisconnected: break
                case .chatMessageReceived(let message):
                    await showAlert("Chat: \(message.text)")
                @unknown default: break
                }
            }
        }
        await state.setChatEventTask(chatEventTask)
    }
    
    func cancelSubscriptions() async {
        await state.callEventsTask?.cancel()
        await state.chatEventTask?.cancel()
        await state.setCallEventTask(nil)
        await state.setChatEventTask(nil)
    }
}
