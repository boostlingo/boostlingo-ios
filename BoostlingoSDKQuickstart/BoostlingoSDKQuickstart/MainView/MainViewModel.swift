//
//  MainViewModel.swift
//  BoostlingoQuickstart
//
//  Created by Leonid Gorbarenko on 20.05.2025.
//  Copyright © 2025 Boostlingo LLC. All rights reserved.
//

import UIKit
import BoostlingoSDK
import AVFoundation
import SwiftUI

@MainActor
protocol ViewControllerDelegate : AnyObject {
    
    var callId: Int? { get set }
}

actor MainState {
    
    let navigationPath: Binding<[Screen]>
    
    var boostlingo: Boostlingo?
    
    init(navigationPath: Binding<[Screen]>) {
        self.navigationPath = navigationPath
    }
    
    func setBoostlingoSDK(_ boostlingo: Boostlingo?) {
        self.boostlingo = boostlingo
    }
}

@MainActor
@Observable
final class MainViewModel: Sendable, ViewControllerDelegate {
    
    enum State {
        case notAuthenticated, loading, authenticated
    }

    var callId: Int?
    var authState: State = .notAuthenticated

    var authToken: String = ""
    var selectedRegion: String?
    var selectedLanguageFrom: Int?
    var selectedLanguageTo: Int?
    var selectedServiceType: Int?
    var selectedGender: Int?

    var regions: [String] = []
    var languages: [Language] = []
    var serviceTypes: [ServiceType] = []
    var genders: [Gender] = []
    
    var alertMessage: String? = nil
    
    let state: MainState
    
    init(navigationPath: Binding<[Screen]>) {
        state = MainState(navigationPath: navigationPath)
        print("BoostlingoSDK verion: \(Boostlingo.getVersion())")
        regions = Boostlingo.getRegions()
        selectedRegion = regions.first(where: { $0 == "staging" })
    }

    func signIn() {
        Task {
            do {
                authState = .loading
                // For production builds use BLNullLogger() or your custom logger
                let boostlingo = Boostlingo(
                    authToken: authToken,
                    region: selectedRegion!,
                    logger: BLPrintLogger()
                )
                await state.setBoostlingoSDK(boostlingo)
                try await boostlingo.initialize()

                let dictionaries = try await boostlingo.getCallDictionaries()
                languages = dictionaries?.languages ?? []
                serviceTypes = dictionaries?.serviceTypes ?? []
                genders = dictionaries?.genders ?? []

                selectedLanguageFrom = languages.first(where: { $0.id == 9 })?.id
                selectedLanguageTo = languages.first(where: { $0.id == 32 })?.id
                selectedServiceType = serviceTypes.first(where: { $0.id == 1 })?.id
                selectedGender = genders.first?.id
                authState = .authenticated
            } catch {
                authState = .notAuthenticated
                showAlert("Sign in failed: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    private func showAlert(_ message: String) {
        alertMessage = message
    }

    func startAudioCall() {
        Task {
            let granted = await checkRecordPermission()
            guard granted else {
                showAlert("Microphone permission not granted")
                return
            }
            await startCall(isVideo: false)
        }
    }
    
    private func checkRecordPermission() async -> Bool {
        let permission = AVAudioApplication.shared.recordPermission

        switch permission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }
    
    private func startCall(isVideo: Bool) async {
        do {
            guard let boostlingo = await state.boostlingo else { return }
            
            let form = try await boostlingo.getPreCallCustomForm()
            let fields = form?.fields ?? []

            let callRequest = CallRequest(
                languageFromId: selectedLanguageFrom!,
                languageToId: selectedLanguageTo!,
                serviceTypeId: selectedServiceType!,
                genderId: selectedGender,
                isVideo: isVideo,
                data: [AdditionalField(key: "CustomKey", value: "CustomValue")],
                fieldData: fields
            )

            try await state.boostlingo?.validateCallReq(callReq: callRequest)

            if isVideo {
                let vm = VideoCallViewModel(
                    boostlingo: boostlingo,
                    callRequest: callRequest,
                    navigationPath: state.navigationPath
                )
                vm.sendableDelegate.delegate = self
                state.navigationPath.wrappedValue.append(.videoCall(vm))
            } else {
                let vm = VoiceCallViewModel(
                    boostlingo: boostlingo,
                    callRequest: callRequest,
                    navigationPath: state.navigationPath,
                )
                vm.delegate.delegate = self
                state.navigationPath.wrappedValue.append(.voiceCall(vm))
            }
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    func startVideoCall() {
        Task { await startCall(isVideo: true) }
    }

    func fetchLastCallInfo() {
        guard let callId else { return }
        authState = .loading
        Task {
            do {
                let details = try await state.boostlingo?.getCallDetails(callId: callId)
                authState = .authenticated
                let msg = "AccountUniqueId: \(details?.accountUniqueId ?? 0), CallId: \(details?.callId ?? 0), Duration: \(details?.duration ?? 0) sec"
                showAlert(msg)
            } catch {
                authState = .authenticated
                showAlert(error.localizedDescription)
            }
        }
    }
    
    func disposeBoostlingoSDK() {
        Task {
            // clear UI data
            authState = .notAuthenticated
            languages = []
            serviceTypes = []
            genders = []

            selectedLanguageFrom = nil
            selectedLanguageTo = nil
            selectedServiceType = nil
            selectedGender = nil
            
            // Disposing the BoostlingoSDK
            await state.boostlingo?.dispose()
            await state.setBoostlingoSDK(nil)
        }
    }
}
