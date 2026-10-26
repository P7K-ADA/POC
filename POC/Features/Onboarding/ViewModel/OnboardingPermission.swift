//
//  OnboardingPermission.swift
//  POC
//

import SwiftUI
import AVFoundation
import Photos

enum OnboardingPermission: CaseIterable {
    case camera
    case photos

    var title: String {
        switch self {
        case .camera: return "Enable Camera"
        case .photos: return "Enable Photos"
        }
    }

    var message: String {
        switch self {
        case .camera:
            return "Please provide us access to your camera, which is required to capture eye images for screening."
        case .photos:
            return "Allow us to save captured or processed eye images and reports to your Photos library."
        }
    }

    var systemImage: String {
        switch self {
        case .camera: return "camera.fill"
        case .photos: return "photo.on.rectangle.angled"
        }
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var currentIndex = 0
    @Published private(set) var isFinished = false
    @Published private(set) var isNFCDetected = false
    @Published var showsNFCInstruction = false

    let pages = OnboardingPermission.allCases

    private let nfcDetector = NFCFrameDetector()

    var currentPage: OnboardingPermission {
        pages[currentIndex]
    }

    var canAllowCurrentPermission: Bool {
        currentPage != .camera || isNFCDetected
    }

    func startNFCScanning() {
        guard currentPage == .camera, !isNFCDetected else {
            return
        }

        nfcDetector.startScanning { [weak self] in
            Task { @MainActor in
                self?.isNFCDetected = true
            }
        }
    }

    func stopNFCScanning() {
        nfcDetector.stopScanning()
    }

    /// Shows the system permission prompt only after the frame has been detected.
    func allow() async {
        if currentPage == .camera, !isNFCDetected {
            showsNFCInstruction = true
            return
        }

        switch currentPage {
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .notDetermined {
                _ = await AVCaptureDevice.requestAccess(for: .video)
            }
        case .photos:
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            if status == .notDetermined {
                _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            }
        }

        advance()
    }

    /// “Maybe later” – skip without asking.
    func skip() {
        advance()
    }

    private func advance() {
        if currentIndex < pages.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            isFinished = true
        }
    }
}
