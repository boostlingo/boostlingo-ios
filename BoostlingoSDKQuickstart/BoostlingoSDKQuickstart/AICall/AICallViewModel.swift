//
//  AICallViewModel.swift
//  BoostlingoQuickstart
//
//  Copyright © 2026 Boostlingo LLC. All rights reserved.
//

import SwiftUI
import BoostlingoSDK

actor AICallState {

    var callId: Int?
    var callRequest: CallRequest
    var boostlingo: Boostlingo
    var call: BLAICall?

    var callEventsTask: Task<Void, Never>?
    let navigationPath: Binding<[Screen]>

    init(
        callRequest: CallRequest,
        boostlingo: Boostlingo,
        navigationPath: Binding<[Screen]>
    ) {
        self.callRequest = callRequest
        self.boostlingo = boostlingo
        self.navigationPath = navigationPath
    }

    func setCall(_ call: BLAICall?) {
        self.call = call
    }

    func setCallId(_ callId: Int?) {
        self.callId = callId
    }

    func setCallEventTask(_ task: Task<Void, Never>?) {
        self.callEventsTask = task
    }
}

@MainActor
@Observable
final class AICallViewModel: NSObject, Sendable {

    enum State {
        case noCall
        case calling
        case inProgress(interpreterName: String?)
    }

    @ObservationIgnored let delegate = ViewControllerSendableDelegate()
    @ObservationIgnored let state: AICallState

    var callState: State = .noCall
    var isMuted = false
    var isSpeakerOn = false
    var isAISpeaking = false
    var alertMessage: String? = nil

    init(
        boostlingo: Boostlingo,
        callRequest: CallRequest,
        navigationPath: Binding<[Screen]>
    ) {
        self.state = AICallState(
            callRequest: callRequest,
            boostlingo: boostlingo,
            navigationPath: navigationPath
        )
    }

    func startCall() {
        Task {
            do {
                await subscribeOnCallEvents()
                try await state.setCall(
                    state.boostlingo.makeAIInterpreterCall(callRequest: state.callRequest)
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

    func interruptAI() {
        Task {
            do {
                try await state.call?.interrupt()
            } catch {
                await showAlert(error.localizedDescription)
            }
        }
    }

    /// Rolls the AI call over to a human, then replaces this screen with the
    /// Voice Call screen (in adopt mode) to follow the returned `BLVoiceCall`.
    func rolloverToHuman() {
        Task {
            do {
                let humanCall = try await state.boostlingo.rolloverAICall(
                    reasons: [.interpreterQuality],
                    additionalFeedback: "Requested a human interpreter"
                )
                guard let humanCall else {
                    await showAlert("Roll over did not return a voice call")
                    return
                }
                let voiceViewModel = VoiceCallViewModel(
                    boostlingo: await state.boostlingo,
                    callRequest: await state.callRequest,
                    existingCall: humanCall,
                    navigationPath: state.navigationPath
                )
                voiceViewModel.delegate.delegate = delegate.delegate
                // Stop reacting to call events before popping so this screen's
                // disconnect handler can't pop the wrong screen.
                await cancelSubscriptions()
                state.navigationPath.wrappedValue.removeLast()
                state.navigationPath.wrappedValue.append(.voiceCall(voiceViewModel))
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
            guard let participant = await state.call?.participants.first(where: { $0.participantType == .thirdParty }) else {
                await showAlert("No third-party participant to hang up")
                return
            }
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

    private func showAlert(_ message: String) async {
        alertMessage = message
    }

    func subscribeOnCallEvents() async {
        let callEventTask = Task {
            let boostlingo = await state.boostlingo
            for await event in await boostlingo.callEventStream {
                guard !Task.isCancelled else { break }
                switch event {
                case .callDidConnect(let call, participants: _):
                    await state.setCall(call as? BLAICall)
                    await state.setCallId(call.callId)
                    delegate.delegate?.callId = await state.callId
                    isMuted = await call.getIsMuted()
                    callState = .inProgress(
                        interpreterName: await state.call?.interlocutorInfo?.requiredName
                    )
                case .callDidDisconnect(let error):
                    await state.setCall(nil)
                    callState = .noCall
                    let msg = error != nil ? "Call did disconnect with error: \(error!.localizedDescription)" : "Call did disconnect"
                    await showAlert(msg)
                    state.navigationPath.wrappedValue.removeLast()
                    await cancelSubscriptions()
                case .callDidFailToConnect(let error):
                    await state.setCall(nil)
                    callState = .noCall
                    let msg = error != nil ? "Call failed to connect: \(error!.localizedDescription)" : "Call failed to connect"
                    await showAlert(msg)
                    state.navigationPath.wrappedValue.removeLast()
                    await cancelSubscriptions()
                case .aiInterpreterStartedSpeaking:
                    isAISpeaking = true
                case .aiInterpreterStoppedSpeaking:
                    isAISpeaking = false
                case .participantConnected, .participantUpdated, .participantDisconnected:
                    break
                @unknown default:
                    break
                }
            }
        }
        await state.setCallEventTask(callEventTask)
    }

    func cancelSubscriptions() async {
        await state.callEventsTask?.cancel()
        await state.setCallEventTask(nil)
    }
}
