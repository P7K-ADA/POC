//
//  CameraPreview.swift
//  POC
//

import AVFoundation
import SwiftUI
import UIKit

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let onPreviewSizeChanged: (CGSize) -> Void

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.onPreviewSizeChanged = onPreviewSizeChanged
        return view
    }

    func updateUIView(
        _ uiView: PreviewView,
        context: Context
    ) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
        uiView.onPreviewSizeChanged = onPreviewSizeChanged
    }
}

final class PreviewView: UIView {
    var onPreviewSizeChanged: ((CGSize) -> Void)?
    private var lastReportedSize = CGSize.zero

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.size != lastReportedSize else { return }
        lastReportedSize = bounds.size
        onPreviewSizeChanged?(bounds.size)
    }
}
