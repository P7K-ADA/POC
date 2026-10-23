//
//  ScanViewModel.swift
//  POC
//

import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class ScanViewModel: ObservableObject {
    let camera = CameraService()

    @Published var selectedEye: EyeSide = .left
    @Published var selectedImage: UIImage?
    @Published var selectedItem: PhotosPickerItem?
    @Published private(set) var leftImage: UIImage?
    @Published private(set) var rightImage: UIImage?
    @Published private(set) var leftResult: SegmentationResult?
    @Published private(set) var rightResult: SegmentationResult?
    @Published private(set) var isReviewing = false
    @Published private(set) var isAnalyzing = false
    @Published private(set) var completedSession: ScreeningSession?
    @Published var showReport = false
    @Published var errorMessage: String?

    var isLastEye: Bool {
        selectedEye == .right ? leftImage != nil : rightImage != nil
    }

    func handleCapturedImage(_ image: UIImage) {
        selectedImage = image
        selectedItem = nil
        isReviewing = true
        camera.setTorch(enabled: false)
    }

    func loadGalleryImage(_ item: PhotosPickerItem) async {
        do {
            guard
                let data = try await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else {
                errorMessage = "Couldn't load that image. Please choose another."
                return
            }

            camera.stop()
            selectedImage = image
            isReviewing = true
        } catch {
            errorMessage = "Couldn't load the selected image: \(error.localizedDescription)"
        }
    }

    func retakeCurrentEye() {
        if selectedEye == .right {
            rightImage = nil
        } else {
            leftImage = nil
        }

        selectedImage = nil
        selectedItem = nil
        isReviewing = false
        camera.start()
    }

    func chooseAnotherImage() {
        selectedItem = nil
    }

    func useEditedImage(_ image: UIImage) {
        selectedImage = image
        isReviewing = true
    }

    func analyzeCurrentImage() async {
        guard let image = selectedImage, !isAnalyzing else { return }

        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            let service = try ImageInferenceService()
            let result = try service.predict(image: image)

            if selectedEye == .left {
                leftImage = image
                leftResult = result
            } else {
                rightImage = image
                rightResult = result
            }

            if isLastEye {
                saveCurrentSession()
            } else {
                selectedEye = selectedEye == .right ? .left : .right
                selectedImage = nil
                isReviewing = false
                camera.start()
            }
        } catch {
            errorMessage = modelErrorMessage(error, eye: selectedEye)
        }
    }

    func resetScan() {
        selectedImage = nil
        selectedItem = nil
        isReviewing = false
        leftImage = nil
        rightImage = nil
        leftResult = nil
        rightResult = nil
        selectedEye = .left
        isAnalyzing = false
        completedSession = nil
        showReport = false
        camera.start()
    }

    func stopCamera() {
        camera.stop()
    }

    func dismissError() {
        // Defer the published mutation until SwiftUI has finished updating the alert.
        Task { @MainActor [weak self] in
            self?.errorMessage = nil
        }
    }

    private func saveCurrentSession() {
        let sessionID = UUID()

        let leftEye = EyeExaminationRecord(
            sessionID: sessionID,
            eyeSide: .left,
            image: leftImage,
            segmentationResult: leftResult,
            isDummy: leftImage == nil
        )

        let rightEye = EyeExaminationRecord(
            sessionID: sessionID,
            eyeSide: .right,
            image: rightImage,
            segmentationResult: rightResult,
            isDummy: rightImage == nil
        )

        completedSession = ScreeningSession(
            id: sessionID,
            examDate: .now,
            status: .completed,
            leftEye: leftEye,
            rightEye: rightEye
        )
        showReport = true
    }

    private func modelErrorMessage(_ error: Error, eye: EyeSide) -> String {
        let eyeName = eye == .left ? "left eye" : "right eye"
        return "The model was unable to analyze the \(eyeName): \(error.localizedDescription)"
    }
}
