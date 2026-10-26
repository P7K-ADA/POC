//
//  OnboardingPermission.swift
//  POC
//
//  Created by Harley Ganisson on 25/10/26.
//


//
//  OnboardingViewModel.swift
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

    let pages = OnboardingPermission.allCases

    var currentPage: OnboardingPermission { pages[currentIndex] }

    /// Shows the system permission prompt for the current page, then moves on.
    func allow() async {
        switch currentPage {
        case .camera:
            _ = await AVCaptureDevice.requestAccess(for: .video)
        case .photos:
            _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
        advance()
    }

    /// "Maybe later" – skip without asking.
    func skip() {
        advance()
    }

    private func advance() {
        if currentIndex < pages.count - 1 {
            withAnimation { currentIndex += 1 }
        } else {
            isFinished = true
        }
    }
}