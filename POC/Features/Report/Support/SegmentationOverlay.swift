//
//  SegmentationOverlay.swift
//  POC
//
//  Creates transparent disc and cup boundaries for report previews.
//

import UIKit
import CoreGraphics

enum SegmentationOverlay {
    static let discLabel: UInt8 = 1
    static let cupLabel: UInt8 = 2

    /// Creates an overlay in the original photo's coordinate space.
    /// roiRectNormalized describes where the square 512x512 model input came
    /// from inside the upright original photo (x, y, width, height; 0...1).
    static func makeImage(
        from mask: [UInt8],
        width: Int,
        height: Int,
        canvasSize: CGSize,
        roiRectNormalized: CGRect
    ) -> UIImage? {
        guard width > 0, height > 0, mask.count == width * height,
              canvasSize.width > 0, canvasSize.height > 0,
              roiRectNormalized.width > 0, roiRectNormalized.height > 0 else {
            return nil
        }

        var pixels = [UInt8](repeating: 0, count: width * height * 4)

        func labelAt(_ x: Int, _ y: Int) -> UInt8 {
            mask[y * width + x]
        }

        for y in 0..<height {
            for x in 0..<width {
                let label = labelAt(x, y)
                guard label == discLabel || label == cupLabel else { continue }

                let left = x > 0 ? labelAt(x - 1, y) : 0
                let right = x + 1 < width ? labelAt(x + 1, y) : 0
                let up = y > 0 ? labelAt(x, y - 1) : 0
                let down = y + 1 < height ? labelAt(x, y + 1) : 0
                guard left != label || right != label || up != label || down != label else {
                    continue
                }

                let index = (y * width + x) * 4
                if label == discLabel {
                    pixels[index] = 45
                    pixels[index + 1] = 220
                    pixels[index + 2] = 135
                } else {
                    pixels[index] = 255
                    pixels[index + 1] = 75
                    pixels[index + 2] = 85
                }
                pixels[index + 3] = 255
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let maskContext = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ), let maskCG = maskContext.makeImage() else {
            return nil
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)

        let rect = CGRect(
            x: roiRectNormalized.minX * canvasSize.width,
            y: roiRectNormalized.minY * canvasSize.height,
            width: roiRectNormalized.width * canvasSize.width,
            height: roiRectNormalized.height * canvasSize.height
        )

        return renderer.image { _ in
            UIImage(cgImage: maskCG, scale: 1, orientation: .up).draw(in: rect)
        }
    }
}
