//
//  VoiceCallView.swift
//  BoostlingoQuickstart
//
//  Created by Leonid Gorbarenko on 19.05.2025.
//  Copyright © 2025 Boostlingo LLC. All rights reserved.
//

import SwiftUI
import BoostlingoSDK

struct VoiceCallView: View {
    
    @Bindable var viewModel: VoiceCallViewModel

    var body: some View {
        Form {
            Section("Call") {
                Text(callStatus)
                    .multilineTextAlignment(.center)
                
                Toggle("Mute", isOn: Binding(
                    get: { viewModel.isMuted },
                    set: { viewModel.toggleMute($0) }
                ))
                .disabled(!isConnected)
                
                Toggle("Speaker", isOn: Binding(
                    get: { viewModel.isSpeakerOn },
                    set: { viewModel.toggleSpeaker($0) }
                ))
                .disabled(!isConnected)
            }
            Section("Chat") {
                Button("Send Test Message") {
                    viewModel.sendTestMessage()
                }
                .disabled(!isConnected)
            }
            
            Section("Participants") {
                Button("Dial 3rd Party") {
                    viewModel.dialThirdParty()
                }
                .disabled(!isConnected)
                
                Button("Hang Up 3rd Party") {
                    viewModel.hangUpThirdParty()
                }
                .disabled(!isConnected)
                
                Button("Mute 3rd Party") {
                    viewModel.muteThirdParty()
                }
                .disabled(!isConnected)
                
                Button("Confirm 3rd Party Invitation") {
                    viewModel.confirmThirdParty()
                }
                .disabled(!isConnected)
                
                Button("Decline 3rd Party Invitation") {
                    viewModel.declineThirdParty()
                }
                .disabled(!isConnected)
            }
            Section("End call") {
                Button("Hang Up", role: .destructive) {
                    viewModel.hangUp()
                }
            }
        }
        .navigationTitle("Voice Call")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.startCall()
        }
        .alert(
            "Info",
            isPresented: .init(
                get: { viewModel.alertMessage != nil },
                set: { if !$0 { viewModel.alertMessage = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) { viewModel.alertMessage = nil }
            },
            message: {
                if let text = viewModel.alertMessage { Text(text) }
            }
        )
    }

    private var callStatus: String {
        switch viewModel.callState {
        case .noCall:
            return "No active call"
        case .calling:
            return "Calling..."
        case .inProgress(let name):
            return name.map { "Call in progress with \($0)" } ?? "Call in progress"
        }
    }

    private var isConnected: Bool {
        if case .inProgress = viewModel.callState {
            return true
        }
        return false
    }
}

#Preview {
    @Previewable @State var path: [Screen] = []
    NavigationStack(path: $path) {
        VoiceCallView(
            viewModel: VoiceCallViewModel(
                boostlingo: Boostlingo(authToken: "", region: "staging"),
                callRequest: CallRequest(
                    languageFromId: 1,
                    languageToId: 2,
                    serviceTypeId: 1,
                    genderId: nil,
                    data: nil
                ),
                navigationPath: $path
            )
        )
    }
}
