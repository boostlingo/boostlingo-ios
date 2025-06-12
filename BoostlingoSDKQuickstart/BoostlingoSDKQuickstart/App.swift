//
//  App.swift
//  BoostlingoQuickstart
//
//  Created by Leonid Gorbarenko on 21.05.2025.
//  Copyright © 2025 Boostlingo LLC. All rights reserved.
//

import SwiftUI

@main
struct BoostlingoQuickstartApp: App {
    
    var body: some Scene {
        WindowGroup {
            AppView()
        }
    }
}

struct AppView: View {
    
    @State private var path: [Screen] = []

    var body: some View {
        NavigationStack(path: $path) {
            MainView(viewModel: MainViewModel(navigationPath: $path))
                .navigationDestination(for: Screen.self) { screen in
                    switch screen {
                    case .voiceCall(let vm):
                        VoiceCallView(viewModel: vm)
                    case .videoCall(let vm):
                        VideoCallContainerView(viewModel: vm)
                    }
                }
        }
    }
}

enum Screen: Hashable {
    
    case voiceCall(VoiceCallViewModel)
    case videoCall(VideoCallViewModel)
}
