//
//  ImageReviewViewModel.swift
//  POC
//

import SwiftUI
import UIKit

@MainActor
final class ImageReviewViewModel: ObservableObject {
    @Published private(set) var zoom: CGFloat = 1
    @Published private(set) var offset: CGSize = .zero
    @Published private(set) var cropMode = false

    private var lastZoom: CGFloat = 1
    private var lastOffset: CGSize = .zero

    func updateZoom(with value: CGFloat) {
        zoom = min(max(lastZoom * value, 1), 5)
    }

    func finishZoom() {
        lastZoom = zoom
    }

    func updateOffset(with translation: CGSize) {
        offset = CGSize(
            width: lastOffset.width + translation.width,
            height: lastOffset.height + translation.height
        )
    }

    func finishDrag() {
        lastOffset = offset
    }

    func toggleCropMode() {
        cropMode.toggle()
    }

    func applyCrop(to image: UIImage) -> UIImage? {
        guard cropMode else {
            cropMode = true
            return nil
        }

        guard let croppedImage = centerSquareCrop(image) else {
            return nil
        }

        cropMode = false
        resetView()
        return croppedImage
    }

    func resetView() {
        zoom = 1
        lastZoom = 1
        offset = .zero
        lastOffset = .zero
    }

    private func centerSquareCrop(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let side = min(cgImage.width, cgImage.height)
        let rect = CGRect(
            x: (cgImage.width - side) / 2,
            y: (cgImage.height - side) / 2,
            width: side,
            height: side
        )

        guard let cropped = cgImage.cropping(to: rect) else {
            return nil
        }

        return UIImage(
            cgImage: cropped,
            scale: image.scale,
            orientation: image.imageOrientation
        )
    }
}
