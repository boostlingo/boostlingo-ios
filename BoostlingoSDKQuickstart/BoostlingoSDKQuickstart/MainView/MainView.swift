//
//  MainView.swift
//  BoostlingoQuickstart
//
//  Created by Leonid Gorbarenko on 20.05.2025.
//  Copyright © 2025 Boostlingo LLC. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @Bindable var viewModel: MainViewModel

    var body: some View {
        Form {
            Section("Auth") {
                TextField("Token", text: $viewModel.authToken)
                Picker(
                    "Region",
                    selection: Binding(
                        get: {
                            viewModel.selectedRegion ?? ""
                        },
                        set: {
                            viewModel.selectedRegion = $0
                        }
                    )) {
                        ForEach(
                            viewModel.regions,
                            id: \.self
                        ) {
                            Text($0)
                        }
                    }
                    Button("Sign In", action: viewModel.signIn)
                        .disabled(viewModel.authState != .notAuthenticated)
                }

            Section("Call Options") {
                Picker("Language From", selection: Binding(get: {
                    viewModel.selectedLanguageFrom ?? 0
                }, set: {
                    viewModel.selectedLanguageFrom = $0
                })) {
                    ForEach(viewModel.languages, id: \.id) {
                        Text($0.name).tag($0.id)
                    }
                }

                Picker("Language To", selection: Binding(get: {
                    viewModel.selectedLanguageTo ?? 0
                }, set: {
                    viewModel.selectedLanguageTo = $0
                })) {
                    ForEach(viewModel.languages, id: \.id) {
                        Text($0.name).tag($0.id)
                    }
                }

                Picker("Service Type", selection: Binding(get: {
                    viewModel.selectedServiceType ?? 0
                }, set: {
                    viewModel.selectedServiceType = $0
                })) {
                    ForEach(viewModel.serviceTypes, id: \.id) {
                        Text($0.name).tag($0.id)
                    }
                }

                Picker("Gender", selection: Binding(get: {
                    viewModel.selectedGender ?? 0
                }, set: {
                    viewModel.selectedGender = $0
                })) {
                    ForEach(viewModel.genders, id: \.id) {
                        Text($0.name).tag($0.id)
                    }
                }
            }

            Section("Call") {
                Button("Voice Call", action: viewModel.startAudioCall)
                    .disabled(viewModel.authState != .authenticated)

                Button("Video Call", action: viewModel.startVideoCall)
                    .disabled(viewModel.authState != .authenticated)

                Button("Last Call Info", action: viewModel.fetchLastCallInfo)
                    .disabled(viewModel.authState != .authenticated || viewModel.callId == nil)
            }
            
            Section("Test") {
                Button("Dispose Boostlingo SDK", action: viewModel.disposeBoostlingoSDK)
                    .disabled(viewModel.authState != .authenticated)
            }
        }
        .navigationTitle("Setup")
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
    }
}

#Preview {
    @Previewable @State var path: [Screen] = []
    NavigationStack(path: $path) {
        MainView(
            viewModel: MainViewModel(navigationPath: $path)
        )
    }
}
