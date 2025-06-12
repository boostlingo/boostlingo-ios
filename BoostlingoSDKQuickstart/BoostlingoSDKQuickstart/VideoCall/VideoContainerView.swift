//
//  VideoContainerView.swift
//  BoostlingoQuickstart
//
//  Created by Leonid Gorbarenko on 20.05.2025.
//  Copyright © 2025 Boostlingo LLC. All rights reserved.
//

import BoostlingoSDK
import SwiftUI
import TwilioVideo

struct VideoViewContainer: UIViewRepresentable {
    let videoView: VideoView

    func makeUIView(
        context: Context
    ) -> VideoView {
        videoView.contentMode = .scaleAspectFit
        return videoView
    }

    func updateUIView(
        _ uiView: VideoView,
        context: Context
    ) {}
}


struct VideoCallContainerView: View {
    
    @State private var localView = VideoView()
    @State private var remoteView = VideoView()
    @State private var thirdPartyParticipantView = VideoView()
    @Bindable var viewModel: VideoCallViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VideoViewContainer(videoView: remoteView)
                .ignoresSafeArea()
                .background(Color.black)

            VideoViewContainer(videoView: localView)
                .frame(width: 120, height: 160)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
                .padding()
            
            if viewModel.remoteParticipantsCount > 1 {
                VideoViewContainer(videoView: thirdPartyParticipantView)
                    .frame(width: 120, height: 160)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
                    .padding()
                    .offset(y: 200)
            }

            VStack {
                Spacer()
                VideoCallView(viewModel: viewModel)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            viewModel.startCall(
                localView: localView,
                remoteView: remoteView,
                thirdPartyParticipantView: thirdPartyParticipantView
            )
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
                if let text = viewModel.alertMessage {
                    Text(text)
                }
            }
        )
        .navigationTitle("Video Call")
        .navigationBarBackButtonHidden(true)
    }
}
