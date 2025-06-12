//
//  VideoCallViewModel.swift
//  BoostlingoQuickstart
//
//  Created by Leonid Gorbarenko on 20.05.2025.
//  Copyright © 2025 Boostlingo LLC. All rights reserved.
//

import SwiftUI
import BoostlingoSDK
import TwilioVideo

actor VideoCallState {
    
    var boostlingo: BoostlingoSDK
    var callRequest: CallRequest
    var call: BLVideoCall?
    weak var removeView: VideoView?
    weak var thirdPartyParticipantView: VideoView?
    
    var callEventsTask: Task<Void, Never>?
    var chatEventTask: Task<Void, Never>?
    let navigationPath: Binding<[Screen]>
    
    init(
        boostlingo: BoostlingoSDK,
        callRequest: CallRequest,
        navigationPath: Binding<[Screen]>
    ) {
        self.boostlingo = boostlingo
        self.callRequest = callRequest
        self.navigationPath = navigationPath
    }
    
    func setCall(_ call: BLVideoCall?) {
        self.call = call
    }
    
    func setRemoteView(_ remoteView: VideoView?) {
        self.removeView = remoteView
    }
    
    func setThirdPartyParticipantView(_ thirdPartyParticipantView: VideoView?) {
        self.thirdPartyParticipantView = thirdPartyParticipantView
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
final class VideoCallViewModel: NSObject, Sendable {

    enum CallState {
        case noCall
        case calling
        case inProgress(interpreterName: String?)
    }
    
    var callState: CallState = .noCall
    var isMuted = false
    var isVideoEnabled = true
    var remoteParticipantsCount: Int = 0
    
    var alertMessage: String? = nil

    @ObservationIgnored let sendableDelegate = ViewControllerSendableDelegate()
    @ObservationIgnored let state: VideoCallState
    
    init(
        boostlingo: BoostlingoSDK,
        callRequest: CallRequest,
        navigationPath: Binding<[Screen]>
    ) {
        state = VideoCallState(
            boostlingo: boostlingo,
            callRequest: callRequest,
            navigationPath: navigationPath
        )
    }

    func startCall(
        localView: VideoView,
        remoteView: VideoView,
        thirdPartyParticipantView: VideoView
    ) {
        Task {
            do {
                await state.setRemoteView(remoteView)
                await state.setThirdPartyParticipantView(thirdPartyParticipantView)
                await subscribeOnCallEvents()
                await subscribeOnChatEvents()
                let call = try await state.boostlingo.makeVideoCall(
                    callRequest: await state.callRequest,
                    localVideoView: localView
                )
                await state.setCall(call)
                callState = .calling
            } catch {
                callState = .noCall
                await showAlert("Call failed: \(error.localizedDescription)")
                state.navigationPath.wrappedValue.removeLast()
                await cancelSubscriptions()
            }
        }
    }

    func hangUp() {
        Task {
            callState = .noCall
            do {
                try await state.boostlingo.hangUp()
            } catch {
                await showAlert("\(error.localizedDescription)")
            }
        }
    }

    func toggleMute() {
        Task {
            guard let call = await state.call else { return }
            await call.setIsMuted(!call.getIsMuted())
            isMuted = await call.getIsMuted()
        }
    }
    
    func toggleVideo() {
        Task {
            guard let call = await state.call else { return }
            await call.setIsVideoEnabled(!call.getIsVideoEnabled())
            isVideoEnabled = await call.getIsVideoEnabled()
        }
    }

    func flipCamera() {
        Task { await state.call?.flipCamera() }
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

    private func showAlert(_ message: String) async {
        alertMessage = message
    }
}

// MARK: - Boostlingo Delegates

extension VideoCallViewModel {
    
    func subscribeOnCallEvents() async {
        let callEventTask = Task {
            for await event in await state.boostlingo.callEventStream {
                guard !Task.isCancelled else { break }
                switch event {
                case .callDidConnect(let call, participants: let participants):
                    let videoCall = call as? BLVideoCall
                    await state.setCall(videoCall)
                    
                    if let identity = participants.first?.identity,
                       let renderer = await state.removeView {
                        await videoCall?.addRenderer(for: identity, renderer: renderer)
                    }
                    
                    let callId = await videoCall?.callId
                    sendableDelegate.delegate?.callId = callId
                    let name = await (state.call?.interlocutorInfo?.requiredName)
                    isMuted = await videoCall?.getIsMuted() ?? true
                    isVideoEnabled = await videoCall?.getIsVideoEnabled() ?? false
                    callState = .inProgress(interpreterName: name)
                case .callDidDisconnect(let error):
                    await state.setCall(nil)
                    callState = .noCall
                    let msg = error?.localizedDescription ?? "Call did disconnect"
                    await showAlert(msg)
                    state.navigationPath.wrappedValue.removeLast()
                    await cancelSubscriptions()
                case .callDidFailToConnect(let error):
                    await state.setCall(nil)
                    callState = .noCall
                    let msg = error?.localizedDescription ?? "Call failed to connect"
                    await showAlert(msg)
                    state.navigationPath.wrappedValue.removeLast()
                    await cancelSubscriptions()
                case .participantConnected(let participant, call: let call):
                    print("callParticipantConnected")
                    print("Participants: \(await call.participants.count)")
                    printParticipant(participant)
                    remoteParticipantsCount = await call.participants.count
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
                case .participantUpdated(let participant, call: let call):
                    print("callParticipantUpdated")
                    print("Participants: \(await call.participants.count)")
                    remoteParticipantsCount = await call.participants.count
                    printParticipant(participant)
                case .participantDisconnected(let participant, call: let call):
                    print("callParticipantDisconnected")
                    print("Participants: \(await call.participants.count)")
                    remoteParticipantsCount = await call.participants.count
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
