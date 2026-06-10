//
//  AICallView.swift
//  BoostlingoQuickstart
//
//  Copyright © 2026 Boostlingo LLC. All rights reserved.
//

import SwiftUI
import BoostlingoSDK

struct AICallView: View {

    @Bindable var viewModel: AICallViewModel

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

            Section("AI Interpreter") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(viewModel.isAISpeaking ? "Speaking" : "Idle")
                        .foregroundStyle(viewModel.isAISpeaking ? .green : .secondary)
                }

                Button("Interrupt") {
                    viewModel.interruptAI()
                }
                .disabled(!isConnected || !viewModel.isAISpeaking)
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
            }

            Section("End call") {
                Button("Hang Up", role: .destructive) {
                    viewModel.hangUp()
                }
            }
        }
        .navigationTitle("AI Interpreter Call")
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
