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
    
    let minZoom: CGFloat = 1.0
    let maxZoom: CGFloat = 4.0
    private var currentDevice: AVCaptureDevice?
    
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

            self.enableTorchForRunningSession()

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
            let settings = AVCapturePhotoSettings()
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
        defer {
            queue.async {
                self.capturing = false
            }
        }

        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            DispatchQueue.main.async {
                self.errorMessage = "Photo capture failed."
            }
            return
        }

        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }

    private func enableTorchForRunningSession() {
        guard session.isRunning else { return }

        queue.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.setTorchOnQueue(enabled: true)
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
    
    func setZoom(factor: CGFloat){
        guard let device = currentDevice else {return}
        let targetZoom = max(minZoom, min(factor, maxZoom))
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = targetZoom
            device.unlockForConfiguration()
            DispatchQueue.main.async{
                self.currentZoomFactor = targetZoom
            }
        }
        catch {
                    print("Zoom configuration failed: \(error.localizedDescription)")
                }
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

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(
        _ uiView: PreviewView,
        context: Context
    ) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
