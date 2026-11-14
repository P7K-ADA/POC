
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class ScanViewModel: ObservableObject {
    let camera = CameraService()

    // MARK: - Model Configuration

    private let modelResourceName = "GlaucomaSegV2_EffNetB4"

    // MARK: - Scan State

    @Published var selectedEye: EyeSide = .left
    @Published var selectedImage: UIImage?
    @Published var selectedItem: PhotosPickerItem?

    @Published private(set) var leftImage: UIImage?
    @Published private(set) var rightImage: UIImage?

    @Published private(set) var leftResult: SegmentationResult?
    @Published private(set) var rightResult: SegmentationResult?

    @Published private(set) var isReviewing = false
    @Published private(set) var isAnalyzing = false
    @Published private(set) var analysisErrorMessage: String?

    // MARK: - Current Analysis Debug State

    // Digunakan oleh ImageReviewView.
    @Published private(set) var debugStages: [String: UIImage] = [:]
    @Published private(set) var debugFailureMessage: String?
    @Published private(set) var debugVCDR: Double?
    @Published private(set) var debugConfidence: Double?
    @Published private(set) var qualityWarnings: [String] = []

    // MARK: - Per-eye Debug State

    // Disimpan sampai report selesai dibuat.
    @Published private(set) var leftDebugStages: [String: UIImage] = [:]
    @Published private(set) var rightDebugStages: [String: UIImage] = [:]

    @Published private(set) var leftConfidence: Double?
    @Published private(set) var rightConfidence: Double?

    // MARK: - Navigation State

    @Published private(set) var completedSession: ScreeningSession?
    @Published var showReport = false
    @Published var errorMessage: String?

    private var analysisTask: Task<Void, Never>?
    private var analysisID = UUID()

    var isLastEye: Bool {
        selectedEye == .right ? leftImage != nil : rightImage != nil
    }

    // MARK: - Image Input

    func handleCapturedImage(_ image: UIImage) {
        camera.setTorch(enabled: false)
        camera.stop()
        prepareReview(with: image.croppedToThreeByFour())
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
            prepareReview(with: image)

        } catch {
            errorMessage = "Couldn't load the selected image: \(error.localizedDescription)"
        }
    }

    // MARK: - Review Actions

    func retakeCurrentEye() {
        analysisTask?.cancel()
        analysisTask = nil
        analysisID = UUID()

        clearEyeData(for: selectedEye)
        clearAnalysisState()

        selectedImage = nil
        selectedItem = nil

        isAnalyzing = false
        isReviewing = false

        camera.start()
    }

    func chooseAnotherImage() {
        selectedItem = nil
    }

    func useEditedImage(_ image: UIImage) {
        guard selectedImage != nil, !isAnalyzing else { return }
        commitCurrentImage()
    }

    func commitCurrentImage() {
        guard
            let image = selectedImage,
            !isAnalyzing
        else {
            return
        }

        if selectedEye == .left {
            leftImage = image
        } else {
            rightImage = image
        }

        if isLastEye {
            saveCurrentSession()
        } else {
            selectedEye = selectedEye == .right ? .left : .right
            selectedImage = nil

            clearAnalysisState()

            isReviewing = false
            camera.start()
        }
    }

    // MARK: - Reset

    func resetScan() {
        analysisTask?.cancel()
        analysisTask = nil
        analysisID = UUID()

        selectedImage = nil
        selectedItem = nil

        isReviewing = false

        leftImage = nil
        rightImage = nil

        leftResult = nil
        rightResult = nil

        selectedEye = .left
        isAnalyzing = false

        clearAnalysisState()
        clearEyeData(for: .left)
        clearEyeData(for: .right)

        completedSession = nil
        showReport = false

        camera.start()
    }

    func stopCamera() {
        camera.stop()
    }

    func dismissError() {
        Task { @MainActor [weak self] in
            self?.errorMessage = nil
        }
    }

    // MARK: - Analysis Preparation

    private func prepareReview(with image: UIImage) {
        analysisTask?.cancel()

        let newAnalysisID = UUID()
        let eye = selectedEye

        analysisID = newAnalysisID
        selectedImage = image
        selectedItem = nil

        clearAnalysisState()

        isReviewing = false
        isAnalyzing = true

        analysisTask = Task { [weak self] in
            await self?.analyzeCapturedImage(
                image,
                eye: eye,
                analysisID: newAnalysisID
            )
        }
    }

    private func clearAnalysisState() {
        analysisErrorMessage = nil

        debugStages = [:]
        debugFailureMessage = nil
        debugVCDR = nil
        debugConfidence = nil

        qualityWarnings = []
    }

    private func clearEyeData(for eye: EyeSide) {
        if eye == .left {
            leftImage = nil
            leftResult = nil
            leftDebugStages = [:]
            leftConfidence = nil
        } else {
            rightImage = nil
            rightResult = nil
            rightDebugStages = [:]
            rightConfidence = nil
        }
    }

    // MARK: - Glauma Inference

    private func analyzeCapturedImage(
        _ image: UIImage,
        eye: EyeSide,
        analysisID: UUID
    ) async {
        defer {
            if self.analysisID == analysisID {
                isAnalyzing = false
                isReviewing = true
                analysisTask = nil
            }
        }

        do {
            guard let modelURL = Bundle.main.url(
                forResource: modelResourceName,
                withExtension: "mlmodelc"
            ) else {
                throw NSError(
                    domain: "GlaumaModel",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Model \(modelResourceName).mlmodelc tidak ditemukan di app bundle."
                    ]
                )
            }

            let inferenceService = try GlaumaInferenceService(
                modelURL: modelURL
            )

            let result = try inferenceService.predict(image)

            guard !Task.isCancelled,
                  self.analysisID == analysisID else {
                return
            }

            // Update current analysis state.
            debugStages = result.debugStages
            debugVCDR = result.vCDR
            debugConfidence = result.confidence
            debugFailureMessage = nil
            qualityWarnings = result.warnings

            // Convert inference output to existing report model.
            let segmentationResult = SegmentationResult(
                mask: result.mask,
                width: 512,
                height: 512,
                verticalCDR: result.vCDR,
                discPixelCount: result.mask.filter { $0 >= 1 }.count,
                cupPixelCount: result.mask.filter { $0 == 2 }.count
            )

            // Save result and debug data for the corresponding eye.
            if eye == .left {
                leftResult = segmentationResult
                leftDebugStages = result.debugStages
                leftConfidence = result.confidence
            } else {
                rightResult = segmentationResult
                rightDebugStages = result.debugStages
                rightConfidence = result.confidence
            }

        } catch is CancellationError {
            return

        } catch let failure as GlaumaAnalysisFailure {
            guard self.analysisID == analysisID else { return }

            analysisErrorMessage = failure.message
            debugFailureMessage = failure.message
            debugStages = failure.debugStages

            // Keep available preprocessing stages even when inference fails.
            if eye == .left {
                leftDebugStages = failure.debugStages
                leftConfidence = nil
            } else {
                rightDebugStages = failure.debugStages
                rightConfidence = nil
            }

        } catch {
            guard self.analysisID == analysisID else { return }

            analysisErrorMessage = error.localizedDescription
            debugFailureMessage = error.localizedDescription

            // Generic errors may not contain preprocessing images.
            if eye == .left {
                leftDebugStages = [:]
                leftConfidence = nil
            } else {
                rightDebugStages = [:]
                rightConfidence = nil
            }
        }
    }

    // MARK: - Session

    private func saveCurrentSession() {
        let sessionID = UUID()

        let leftEye = EyeExaminationRecord(
            sessionID: sessionID,
            eyeSide: .left,
            image: leftImage,
            segmentationResult: leftResult,
            debugStages: leftDebugStages,
            confidence: leftConfidence,
            isDummy: leftImage == nil
        )

        let rightEye = EyeExaminationRecord(
            sessionID: sessionID,
            eyeSide: .right,
            image: rightImage,
            segmentationResult: rightResult,
            debugStages: rightDebugStages,
            confidence: rightConfidence,
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
}

// MARK: - UIImage Helpers

private extension UIImage {
    func croppedToThreeByFour() -> UIImage {
        let normalized = normalizedForCropping()

        guard let source = normalized.cgImage else {
            return normalized
        }

        let sourceWidth = CGFloat(source.width)
        let sourceHeight = CGFloat(source.height)
        let sourceRatio = sourceWidth / sourceHeight
        let targetRatio: CGFloat = 3.0 / 4.0

        let cropRect: CGRect

        if sourceRatio > targetRatio {
            let cropWidth = sourceHeight * targetRatio

            cropRect = CGRect(
                x: (sourceWidth - cropWidth) / 2,
                y: 0,
                width: cropWidth,
                height: sourceHeight
            )
        } else {
            let cropHeight = sourceWidth / targetRatio

            cropRect = CGRect(
                x: 0,
                y: (sourceHeight - cropHeight) / 2,
                width: sourceWidth,
                height: cropHeight
            )
        }

        guard let cropped = source.cropping(to: cropRect.integral) else {
            return normalized
        }

        return UIImage(
            cgImage: cropped,
            scale: normalized.scale,
            orientation: .up
        )
    }

    func normalizedForCropping() -> UIImage {
        guard imageOrientation != .up else {
            return self
        }

        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
