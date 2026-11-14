import CoreML
import CoreGraphics
import UIKit
import VideoToolbox

enum GatekeeperIssue: Equatable {
    case dark
    case blur
    case glare
    case noOpticDisc

    var message: String {
        switch self {
        case .dark:
            return "The image is too dark. Please retake the photo with better lighting."
        case .blur:
            return "The image is blurry. Please hold the camera steady and retake the photo."
        case .glare:
            return "The image has too much glare. Please adjust the light and retake the photo."
        case .noOpticDisc:
            return "The optic disc was not detected. Please align the eye with the target and retake the photo."
        }
    }
}

struct GatekeeperResult {
    let issue: GatekeeperIssue?
}

enum GatekeeperError: LocalizedError {
    case modelNotFound
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "MobileNetV3Gatekeeper.mlmodelc was not found."
        case .invalidOutput:
            return "The image-quality model returned an unexpected result."
        }
    }
}

final class GatekeeperService {
    private let model: MLModel
    private let inputSize = 224

    init() throws {
        guard let url = Bundle.main.url(
            forResource: "MobileNetV3Gatekeeper",
            withExtension: "mlmodelc"
        ) else {
            throw GatekeeperError.modelNotFound
        }

        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        model = try MLModel(contentsOf: url, configuration: configuration)
    }

    func evaluate(image: UIImage) throws -> GatekeeperResult {
        let pixelBuffer = try makePixelBuffer(from: image)

        let provider = try MLDictionaryFeatureProvider(
            dictionary: [
                "image": MLFeatureValue(pixelBuffer: pixelBuffer)
            ]
        )

        let prediction = try model.prediction(from: provider)

        guard let logits = prediction.featureValue(
            for: "logits"
        )?.multiArrayValue,
        logits.count == 5 else {
            throw GatekeeperError.invalidOutput
        }

        var bestIndex = 0
        var bestScore = -Double.infinity

        for index in 0..<5 {
            let score = logits[index].doubleValue
            if score > bestScore {
                bestScore = score
                bestIndex = index
            }
        }

        let issue: GatekeeperIssue?
        switch bestIndex {
        case 0:
            issue = nil
        case 1:
            issue = .dark
        case 2:
            issue = .blur
        case 3:
            issue = .glare
        case 4:
            issue = .noOpticDisc
        default:
            throw GatekeeperError.invalidOutput
        }

        return GatekeeperResult(issue: issue)
    }

    private func makePixelBuffer(from image: UIImage) throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            inputSize,
            inputSize,
            kCVPixelFormatType_32BGRA,
            attributes,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer else {
            throw GatekeeperError.invalidOutput
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw GatekeeperError.invalidOutput
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue
                | CGBitmapInfo.byteOrder32Little.rawValue
        )

        guard let context = CGContext(
            data: baseAddress,
            width: inputSize,
            height: inputSize,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw GatekeeperError.invalidOutput
        }

        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: inputSize, height: inputSize))

        guard let cgImage = image.cgImage else {
            throw GatekeeperError.invalidOutput
        }

        context.draw(
            cgImage,
            in: CGRect(x: 0, y: 0, width: inputSize, height: inputSize)
        )

        return pixelBuffer
    }
}
