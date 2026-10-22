//
//  ImageInferenceService.swift
//  POC
//
//  Created by Harley Ganisson on 13/10/26.
//

import Foundation
import UIKit
import CoreML
import CoreGraphics

struct SegmentationResult {
    let mask: [UInt8]
    let width: Int
    let height: Int
    let verticalCDR: Double?
    let discPixelCount: Int
    let cupPixelCount: Int
}

enum InferenceError: LocalizedError {
    case modelNotFound
    case invalidImage
    case invalidInputShape
    case invalidOutputShape
    case emptyMask

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "GlaucomaSegmentation.mlmodelc was not found."
        case .invalidImage:
            return "Could not convert the image to RGB."
        case .invalidInputShape:
            return "The input tensor could not be created."
        case .invalidOutputShape:
            return "The model output has an unexpected shape."
        case .emptyMask:
            return "The model was unable to identify the optic disc or cup."
        }
    }
}

final class ImageInferenceService {
    private let model: MLModel

    // ASSUMPTION: verify these class indices against training labels.
    private let discClassIndex = 1
    private let cupClassIndex = 2

    private let size = 512

    init() throws {
        guard let url = Bundle.main.url(
            forResource: "GlaucomaSegmentation",
            withExtension: "mlmodelc"
        ) else {
            throw InferenceError.modelNotFound
        }

        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all

        model = try MLModel(
            contentsOf: url,
            configuration: configuration
        )
    }

    func predict(image: UIImage) throws -> SegmentationResult {
        let input = try makeInputTensor(from: image)

        let provider = try MLDictionaryFeatureProvider(
            dictionary: [
                "image": MLFeatureValue(multiArray: input)
            ]
        )

        let prediction = try model.prediction(from: provider)

        guard let logits = prediction.featureValue(
            for: "logits"
        )?.multiArrayValue else {
            throw InferenceError.invalidOutputShape
        }

        // Expected output shape: [1, 3, 512, 512].
        guard logits.shape.count == 4,
              logits.shape[0].intValue == 1,
              logits.shape[1].intValue == 3,
              logits.shape[2].intValue == size,
              logits.shape[3].intValue == size else {
            throw InferenceError.invalidOutputShape
        }

        var mask = [UInt8](
            repeating: 0,
            count: size * size
        )

        var discMinY = size
        var discMaxY = -1
        var cupMinY = size
        var cupMaxY = -1

        var discCount = 0
        var cupCount = 0

        for y in 0..<size {
            for x in 0..<size {
                let pixel = y * size + x

                let background = logits[
                    [0, 0, y, x] as [NSNumber]
                ].doubleValue

                let disc = logits[
                    [0, discClassIndex, y, x] as [NSNumber]
                ].doubleValue

                let cup = logits[
                    [0, cupClassIndex, y, x] as [NSNumber]
                ].doubleValue

                // Argmax of logits; softmax is unnecessary here.
                let classIndex: Int

                if background >= disc && background >= cup {
                    classIndex = 0
                } else if disc >= cup {
                    classIndex = discClassIndex
                } else {
                    classIndex = cupClassIndex
                }

                mask[pixel] = UInt8(classIndex)

                if classIndex == discClassIndex ||
                   classIndex == cupClassIndex {
                    discCount += 1
                    discMinY = min(discMinY, y)
                    discMaxY = max(discMaxY, y)
                }

                if classIndex == cupClassIndex {
                    cupCount += 1
                    cupMinY = min(cupMinY, y)
                    cupMaxY = max(cupMaxY, y)
                }
            }
        }

        guard discMaxY >= discMinY,
              cupMaxY >= cupMinY,
              discCount > 0,
              cupCount > 0 else {
            throw InferenceError.emptyMask
        }

        let discHeight = discMaxY - discMinY + 1
        let cupHeight = cupMaxY - cupMinY + 1

        let ratio = Double(cupHeight) / Double(discHeight)

        return SegmentationResult(
            mask: mask,
            width: size,
            height: size,
            verticalCDR: ratio,
            discPixelCount: discCount,
            cupPixelCount: cupCount
        )
    }

    private func makeInputTensor(
        from image: UIImage
    ) throws -> MLMultiArray {
        let tensor = try MLMultiArray(
            shape: [1, 3, size, size] as [NSNumber],
            dataType: .float16
        )

        // Resize to the model's expected 512 x 512 input.
        let renderFormat = UIGraphicsImageRendererFormat()
        renderFormat.scale = 1
        renderFormat.opaque = true

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: size, height: size),
            format: renderFormat
        )

        let resized = renderer.image { context in
            UIColor.black.setFill()
            context.fill(
                CGRect(x: 0, y: 0, width: size, height: size)
            )
            image.draw(
                in: CGRect(x: 0, y: 0, width: size, height: size)
            )
        }

        guard let cgImage = resized.cgImage else {
            throw InferenceError.invalidImage
        }

        let bytesPerPixel = 4
        let bytesPerRow = size * bytesPerPixel
        var pixels = [UInt8](
            repeating: 0,
            count: size * size * bytesPerPixel
        )

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        
        let renderedSuccessfully = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: size,
                height: size,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            ) else {
                return false
            }

            context.draw(
                cgImage,
                in: CGRect(x: 0, y: 0, width: size, height: size)
            )

            return true
        }

        guard renderedSuccessfully else {
            throw InferenceError.invalidImage
        }

        // NCHW layout: [batch, RGB channel, height, width].
        // Assumption: RGB values normalized to [0, 1].
        // Change this if the training preprocessing differs.
        for y in 0..<size {
            for x in 0..<size {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let pixel = y * size + x

                for channel in 0..<3 {
                    let value = Float(pixels[offset + channel]) / 255.0

                    tensor[
                        [0, channel, y, x] as [NSNumber]
                    ] = NSNumber(value: value)
                }

                _ = pixel
            }
        }

        return tensor
    }
}
