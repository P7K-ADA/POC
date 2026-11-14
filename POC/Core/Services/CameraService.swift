//
//  CameraService.swift
//  POC
//
//  Created by Harley Ganisson on 13/10/26.
//

import SwiftUI
import AVFoundation
import UIKit

final class CameraService: NSObject, ObservableObject,
                           AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()

    @Published var isReady = false
    @Published var status = "Starting camera..."
    @Published var errorMessage: String?
    @Published var capturedImage: UIImage?
    @Published var currentZoomFactor: CGFloat = 1.0
    @Published var isFlashEnabled = false
    
    let minZoom: CGFloat = 1.0
    let maxZoom: CGFloat = 4.0
    private var currentDevice: AVCaptureDevice?
    private var captureZoomFactor: CGFloat = 1.0
    private var previewAspectRatio: CGFloat = 3.0 / 4.0
    private var capturePreviewAspectRatio: CGFloat = 3.0 / 4.0
    
    private let photoOutput = AVCapturePhotoOutput()

    private let queue = DispatchQueue(label: "glaucoscan.camera")
    private var configured = false
    private var capturing = false

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configure()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) {
                [weak self] granted in
                guard let self else { return }

                if granted {
                    self.configure()
                } else {
                    DispatchQueue.main.async {
                        self.status = "Camera access denied"
                        self.errorMessage =
                            "Enable camera access in Settings."
                    }
                }
            }

        case .denied, .restricted:
            DispatchQueue.main.async {
                self.status = "Camera access required"
                self.errorMessage =
                    "Enable camera access in Settings."
            }

        @unknown default:
            DispatchQueue.main.async {
                self.status = "Camera unavailable"
            }
        }
    }

    private func configure() {
        queue.async {
            if !self.configured {
                self.session.beginConfiguration()
                self.session.sessionPreset = .photo

                guard
                    let device = AVCaptureDevice.default(
                        .builtInWideAngleCamera,
                        for: .video,
                        position: .back
                    ),
                    let input = try? AVCaptureDeviceInput(
                        device: device
                    ),
                    self.session.canAddInput(input),
                    self.session.canAddOutput(self.photoOutput)
                else {
                    self.session.commitConfiguration()
                    DispatchQueue.main.async {
                        self.status = "Camera unavailable"
                        self.errorMessage =
                            "Could not configure the camera."
                    }
                    return
                }

                self.session.addInput(input)
                self.session.addOutput(self.photoOutput)
                self.currentDevice = device
                self.session.commitConfiguration()
                self.configured = true
            }

            if !self.session.isRunning {
                self.session.startRunning()
            }

            DispatchQueue.main.async {
                self.isReady = true
                self.status = "Camera ready"
                self.errorMessage = nil
            }
        }
    }

    func capturePhoto() {
        queue.async {
            guard self.configured,
                  self.session.isRunning,
                  !self.capturing else { return }

            self.capturing = true
            self.captureZoomFactor = self.currentZoomFactor
            self.capturePreviewAspectRatio = self.previewAspectRatio
            let settings = AVCapturePhotoSettings()
            if self.isFlashEnabled,
               self.photoOutput.supportedFlashModes.contains(.on) {
                settings.flashMode = .on
            } else if self.photoOutput.supportedFlashModes.contains(.off) {
                settings.flashMode = .off
            }
            self.photoOutput.capturePhoto(
                with: settings,
                delegate: self
            )
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            queue.async {
                self.capturing = false
            }
            DispatchQueue.main.async {
                self.errorMessage = "Photo capture failed."
            }
            return
        }

        queue.async {
            let zoomedImage = self.imageApplyingZoom(
                image,
                factor: self.captureZoomFactor
            )
            let processedImage = self.imageMatchingPreview(
                zoomedImage,
                previewAspectRatio: self.capturePreviewAspectRatio
            )
            self.capturing = false

            DispatchQueue.main.async {
                self.capturedImage = processedImage
            }
        }
    }

    private func imageApplyingZoom(
        _ image: UIImage,
        factor: CGFloat
    ) -> UIImage {
        guard factor > 1.0, let source = image.cgImage else {
            return image
        }

        let sourceWidth = CGFloat(source.width)
        let sourceHeight = CGFloat(source.height)
        let cropWidth = sourceWidth / factor
        let cropHeight = sourceHeight / factor
        let cropRect = CGRect(
            x: (sourceWidth - cropWidth) / 2,
            y: (sourceHeight - cropHeight) / 2,
            width: cropWidth,
            height: cropHeight
        ).integral

        guard let croppedSource = source.cropping(to: cropRect) else {
            return image
        }

        return UIImage(
            cgImage: croppedSource,
            scale: image.scale,
            orientation: image.imageOrientation
        )
    }

    /// Crops the 3:4 photo so its visible width matches the aspect-fill camera preview.
    private func imageMatchingPreview(
        _ image: UIImage,
        previewAspectRatio: CGFloat
    ) -> UIImage {
        let normalized = normalizedUpright(image)
        guard let source = normalized.cgImage else {
            return normalized
        }

        let sourceSize = CGSize(width: source.width, height: source.height)
        let targetAspectRatio: CGFloat = 3.0 / 4.0
        let sourceAspectRatio = sourceSize.width / sourceSize.height

        var cropSize: CGSize
        if sourceAspectRatio > targetAspectRatio {
            cropSize = CGSize(
                width: sourceSize.height * targetAspectRatio,
                height: sourceSize.height
            )
        } else {
            cropSize = CGSize(
                width: sourceSize.width,
                height: sourceSize.width / targetAspectRatio
            )
        }

        // Aspect-fill crops the live preview horizontally on tall phone screens.
        // Applying the same scale keeps the saved 3:4 photo framed like the preview.
        let previewScale = min(
            1,
            max(0.01, previewAspectRatio / targetAspectRatio)
        )
        cropSize.width *= previewScale
        cropSize.height *= previewScale

        let cropRect = CGRect(
            x: (sourceSize.width - cropSize.width) / 2,
            y: (sourceSize.height - cropSize.height) / 2,
            width: cropSize.width,
            height: cropSize.height
        ).integral

        guard let croppedSource = source.cropping(to: cropRect) else {
            return normalized
        }

        return UIImage(cgImage: croppedSource, scale: normalized.scale, orientation: .up)
    }

    private func normalizedUpright(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    func setTorch(enabled: Bool) {
        queue.async {
            self.setTorchOnQueue(enabled: enabled)
        }
    }

    private func setTorchOnQueue(enabled: Bool) {
        guard let device = currentDevice,
              device.hasTorch,
              device.isTorchModeSupported(enabled ? .on : .off)
        else {
            return
        }

        do {
            try device.lockForConfiguration()
            if enabled, device.isTorchAvailable {
                try device.setTorchModeOn(
                    level: AVCaptureDevice.maxAvailableTorchLevel
                )
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {
            print("Torch configuration failed: \(error.localizedDescription)")
        }
    }

    func stop() {
        queue.async {
            self.setTorchOnQueue(enabled: false)

            if self.session.isRunning {
                self.session.stopRunning()
            }

            DispatchQueue.main.async {
                self.isReady = false
            }
        }
    }
    
    func setZoom(factor: CGFloat) {
        queue.async {
            guard let device = self.currentDevice else { return }
            let targetZoom = max(
                self.minZoom,
                min(factor, self.maxZoom)
            )

            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = targetZoom
                device.unlockForConfiguration()

                self.captureZoomFactor = targetZoom
                DispatchQueue.main.async {
                    self.currentZoomFactor = targetZoom
                }
            } catch {
                print(
                    "Zoom configuration failed: \(error.localizedDescription)"
                )
            }
        }
    }

    func setPreviewSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        queue.async {
            self.previewAspectRatio = size.width / size.height
        }
    }

    func toggleFlash() {
        isFlashEnabled.toggle()
    }
    
    func focus(at devicePoint: CGPoint) {
        guard let device = currentDevice else {return}
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = devicePoint
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                device.exposurePointOfInterest = devicePoint
                device.focusMode = .autoFocus
            }
            device.unlockForConfiguration()
        }
        catch{
            print("Focus configuration failed: \(error.localizedDescription)")
        }
    }
}
