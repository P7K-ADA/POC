//
//  SegmentationOverkay.swift
//  POC
//
//  Created by Harley Ganisson on 14/10/26.
//

import UIKit

enum SegmentationOverlay {
    static let discLabel: UInt8 = 1
    static let cupLabel: UInt8 = 2

    static func makeImage(from result: SegmentationResult) -> UIImage? {
        let width = result.width
        let height = result.height

        guard width > 0,
              height > 0,
              result.mask.count == width * height else {
            return nil
        }

        var pixels = [UInt8](
            repeating: 0,
            count: width * height * 4
        )

        func labelAt(_ x: Int, _ y: Int) -> UInt8 {
            result.mask[y * width + x]
        }

        for y in 0..<height {
            for x in 0..<width {
                let label = labelAt(x, y)

                guard label == discLabel || label == cupLabel else {
                    continue
                }

                let left = x > 0 ? labelAt(x - 1, y) : 0
                let right = x + 1 < width ? labelAt(x + 1, y) : 0
                let up = y > 0 ? labelAt(x, y - 1) : 0
                let down = y + 1 < height ? labelAt(x, y + 1) : 0

                let isBoundary =
                    left != label ||
                    right != label ||
                    up != label ||
                    down != label

                guard isBoundary else { continue }

                let index = (y * width + x) * 4

                if label == discLabel {
                    // Green disc boundary
                    pixels[index] = 45
                    pixels[index + 1] = 220
                    pixels[index + 2] = 135
                    pixels[index + 3] = 255
                } else {
                    // Red cup boundary
                    pixels[index] = 255
                    pixels[index + 1] = 75
                    pixels[index + 2] = 85
                    pixels[index + 3] = 255
                }
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ),
        let cgImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
