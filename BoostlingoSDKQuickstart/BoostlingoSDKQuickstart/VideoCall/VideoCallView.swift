//
//  VideoCallView.swift
//  BoostlingoQuickstart
//
//  Created by Leonid Gorbarenko on 20.05.2025.
//  Copyright © 2025 Boostlingo LLC. All rights reserved.
//

import SwiftUI
import BoostlingoSDK

struct VideoCallView: View {
    @Bindable var viewModel: VideoCallViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text(statusText)
                .padding(.bottom, 8)
                .foregroundStyle(.white)
            
            Button(viewModel.isMuted ? "Mic muted" : "Mic unmuted") {
                viewModel.toggleMute()
            }
            
            Button(viewModel.isVideoEnabled ? "Camera enabled" : "Camera disabled") {
                viewModel.toggleVideo()
            }
            
            Button("Flip Camera") {
                viewModel.flipCamera()
            }
            
            Button("Send Test Message") {
                viewModel.sendTestMessage()
            }
            
            Button("Dial 3rd Party") {
                viewModel.dialThirdParty()
            }
            
            Button("Hang Up 3rd Party") {
                viewModel.hangUpThirdParty()
            }
            
            Button("Mute 3rd Party") {
                viewModel.muteThirdParty()
            }
            
            Button("Confirm 3rd Party Invitation") {
                viewModel.confirmThirdParty()
            }
            
            Button("Decline 3rd Party Invitation") {
                viewModel.declineThirdParty()
            }

            Button("Hang Up", role: .destructive) {
                viewModel.hangUp()
            }
        }
        .padding()
        .background(.clear)
        .cornerRadius(12)
    }

    private var statusText: String {
        switch viewModel.callState {
        case .noCall:
            return "No active call"
        case .calling:
            return "Calling..."
        case .inProgress(let name):
            return name.map { "Call in progress with \($0)" } ?? "Call in progress"
        }
    }
}

#Preview {
    @Previewable @State var path: [Screen] = []
    NavigationStack(path: $path) {
        VideoCallView(
            viewModel: VideoCallViewModel(
                boostlingo: BoostlingoSDK(authToken: "", region: "staging"),
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
