import Foundation
import UIKit
import CoreML
import CoreVideo

struct GlaumaInferenceResult {
    let mask: [UInt8]                 // 0 background, 1 OD, 2 OC; 512x512
    let vCDR: Double
    let confidence: Double            // model score, not clinical accuracy
    let qualityStatus: String
    let qualityMetrics: [String: Double]
    let warnings: [String]
    let debugStages: [String: UIImage]
    /// ROI rectangle in normalized coordinates of the upright original photo.
    let roiRectNormalized: CGRect
}

struct GlaumaAnalysisFailure: LocalizedError {
    let code: String
    let message: String
    let metrics: [String: Double]
    let debugStages: [String: UIImage]
    var errorDescription: String? { message }
}

final class GlaumaInferenceService: @unchecked Sendable {
    private let model: MLModel
    private let side = 512
    private let inputName = "image"
    private let outputName = "logits"
    private let useHorizontalFlipTTA: Bool
    private let capturesDebugStages: Bool

    /// Add the .mlpackage to the Xcode target and load the compiled .mlmodelc URL.
    init(
        modelURL: URL,
        useHorizontalFlipTTA: Bool = false,
        capturesDebugStages: Bool = true
    ) throws {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        self.model = try MLModel(contentsOf: modelURL, configuration: config)
        self.useHorizontalFlipTTA = useHorizontalFlipTTA
        self.capturesDebugStages = capturesDebugStages
    }

    func predict(_ source: UIImage) throws -> GlaumaInferenceResult {
        guard let upright = source.normalizedUpright(),
              let (rgb, width, height) = upright.rgbBytes() else {
            throw GlaumaAnalysisFailure(code: "INVALID_IMAGE",
                message: "Gambar tidak dapat dibaca. Silakan ambil foto ulang.",
                metrics: [:], debugStages: [:])
        }

        let prep = GlaumaOpenCVBridge.prepareRGB(
            rgb,
            width: width,
            height: height,
            captureDebugStages: capturesDebugStages
        )
        let metrics = Self.doubleMetrics(prep["metrics"])
        let stageData = prep["stages"] as? [String: Data] ?? [:]
        let stageSizes = prep["stageSizes"] as? [String: [NSNumber]] ?? [:]
        let debugStages = Self.decodeStages(stageData, sizes: stageSizes)


        guard (prep["ok"] as? Bool) == true,
              let processed = prep["rgbData"] as? Data else {
            let code = prep["reason"] as? String ?? "PREPROCESS_FAIL"
            let message = prep["message"] as? String ?? Self.message(for: code)
            throw GlaumaAnalysisFailure(code: code, message: message,
                                        metrics: metrics, debugStages: debugStages)
        }

        let roiValues = prep["roiRectNormalized"] as? [NSNumber] ?? []
        guard roiValues.count == 4 else {
            throw GlaumaAnalysisFailure(
                code: "ROI_METADATA_MISSING",
                message: "Koordinat optic disc ROI tidak tersedia. Silakan proses ulang foto.",
                metrics: metrics,
                debugStages: debugStages
            )
        }
        let roiRectNormalized = CGRect(
            x: roiValues[0].doubleValue,
            y: roiValues[1].doubleValue,
            width: roiValues[2].doubleValue,
            height: roiValues[3].doubleValue
        )
        guard roiRectNormalized.minX >= 0, roiRectNormalized.minY >= 0,
              roiRectNormalized.width > 0, roiRectNormalized.height > 0,
              roiRectNormalized.maxX <= 1.0001, roiRectNormalized.maxY <= 1.0001 else {
            throw GlaumaAnalysisFailure(
                code: "ROI_METADATA_INVALID",
                message: "Koordinat optic disc ROI tidak valid. Silakan proses ulang foto.",
                metrics: metrics,
                debugStages: debugStages
            )
        }


        guard let logits0 = runModel(rgb: processed) else {
            throw GlaumaAnalysisFailure(code: "MODEL_OUTPUT",
                message: "Output model tidak sesuai dengan format yang diharapkan.",
                metrics: metrics, debugStages: debugStages)
        }

        var probabilities = logits0
        if useHorizontalFlipTTA, let flipped = Self.flipRGB(processed, side: side),
           let logits1 = runModel(rgb: flipped) {
            probabilities = Self.averageWithUnflippedTTA(logits0, logits1, side: side)
        }

        let (rawMask, confidence) = Self.argmax(probabilities, side: side)
        let (cleanMask, postWarnings) = Self.postprocess(rawMask, side: side)

        let discRows = cleanMask.indices.filter { cleanMask[$0] >= 1 }.map { $0 / side }
        let cupRows = cleanMask.indices.filter { cleanMask[$0] == 2 }.map { $0 / side }
        guard !discRows.isEmpty else {
            throw GlaumaAnalysisFailure(code: "EMPTY_DISC_MASK",
                message: Self.message(for: "EMPTY_DISC_MASK"),
                metrics: metrics, debugStages: debugStages)
        }
        guard !cupRows.isEmpty else {
            throw GlaumaAnalysisFailure(code: "EMPTY_CUP_MASK",
                message: Self.message(for: "EMPTY_CUP_MASK"),
                metrics: metrics, debugStages: debugStages)
        }
        guard confidence >= 0.55 else {
            throw GlaumaAnalysisFailure(code: "LOW_SEGMENTATION_CONFIDENCE",
                message: Self.message(for: "LOW_SEGMENTATION_CONFIDENCE"),
                metrics: metrics, debugStages: debugStages)
        }

        let discHeight = Self.robustHeight(discRows)
        let cupHeight = Self.robustHeight(cupRows)
        guard discHeight > 0, cupHeight > 0 else {
            throw GlaumaAnalysisFailure(code: "INVALID_SEGMENTATION",
                message: Self.message(for: "INVALID_SEGMENTATION"),
                metrics: metrics, debugStages: debugStages)
        }

        var stages = debugStages
        if let finalInput = stages["7. Final input 512x512"] {
            stages["8. Segmentation overlay"] = Self.makeOverlay(
                input: finalInput, mask: cleanMask, side: side
            )
        }

        let prepWarnings = prep["warnings"] as? [String] ?? []
        return GlaumaInferenceResult(
            mask: cleanMask,
            vCDR: cupHeight / discHeight,
            confidence: confidence,
            qualityStatus: prep["status"] as? String ?? "pass",
            qualityMetrics: metrics,
            warnings: prepWarnings + postWarnings,
            debugStages: stages,
            roiRectNormalized: roiRectNormalized
        )
    }

    private func runModel(rgb: Data) -> [Float]? {
        guard let pixelBuffer = Self.makePixelBuffer(rgb: rgb, width: side, height: side) else { return nil }
        do {
            let provider = try MLDictionaryFeatureProvider(
                dictionary: [inputName: MLFeatureValue(pixelBuffer: pixelBuffer)]
            )
            let prediction = try model.prediction(from: provider)
            guard let array = prediction.featureValue(for: outputName)?.multiArrayValue else { return nil }
            return Self.softmaxLogits(array, side: side)
        } catch {
            return nil
        }
    }

    private static func makePixelBuffer(rgb: Data, width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ]
        guard CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                  kCVPixelFormatType_32BGRA, attributes as CFDictionary,
                                  &pixelBuffer) == kCVReturnSuccess,
              let buffer = pixelBuffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let dst = base.assumingMemoryBound(to: UInt8.self)
        let rowBytes = CVPixelBufferGetBytesPerRow(buffer)
        rgb.withUnsafeBytes { raw in
            guard let src = raw.bindMemory(to: UInt8.self).baseAddress else { return }
            for y in 0..<height {
                for x in 0..<width {
                    let si = (y * width + x) * 3
                    let di = y * rowBytes + x * 4
                    dst[di] = src[si + 2]       // B
                    dst[di + 1] = src[si + 1]   // G
                    dst[di + 2] = src[si]       // R
                    dst[di + 3] = 255
                }
            }
        }
        return buffer
    }

    /// Read logits using MLMultiArray strides, then softmax each pixel.
    private static func softmaxLogits(_ array: MLMultiArray, side: Int) -> [Float]? {
        guard array.shape.count == 4,
              array.shape[0].intValue == 1,
              array.shape[1].intValue == 3,
              array.shape[2].intValue == side,
              array.shape[3].intValue == side else { return nil }
        let plane = side * side
        let strides = array.strides.map { $0.intValue }
        var output = [Float](repeating: 0, count: 3 * plane)

        for y in 0..<side {
            for x in 0..<side {
                let pixel = y * side + x
                var logits = [Float](repeating: 0, count: 3)
                for c in 0..<3 {
                    let offset = c * strides[1] + y * strides[2] + x * strides[3]
                    switch array.dataType {
                    case .float32:
                        logits[c] = array.dataPointer.assumingMemoryBound(to: Float32.self)[offset]
                    case .double:
                        logits[c] = Float(array.dataPointer.assumingMemoryBound(to: Double.self)[offset])
                    default:
                        return nil
                    }
                }
                let maximum = logits.max() ?? 0
                let exps = logits.map { exp($0 - maximum) }
                let denominator = max(exps.reduce(0, +), 1e-12)
                for c in 0..<3 { output[c * plane + pixel] = exps[c] / denominator }
            }
        }
        return output
    }

    private static func flipRGB(_ data: Data, side: Int) -> Data? {
        guard data.count == side * side * 3 else { return nil }
        var output = Data(count: data.count)
        data.withUnsafeBytes { srcRaw in
            output.withUnsafeMutableBytes { dstRaw in
                guard let src = srcRaw.bindMemory(to: UInt8.self).baseAddress,
                      let dst = dstRaw.bindMemory(to: UInt8.self).baseAddress else { return }
                for y in 0..<side {
                    for x in 0..<side {
                        let from = (y * side + x) * 3
                        let to = (y * side + (side - 1 - x)) * 3
                        dst[to] = src[from]
                        dst[to + 1] = src[from + 1]
                        dst[to + 2] = src[from + 2]
                    }
                }
            }
        }
        return output
    }

    /// Both inputs are class-major softmax probabilities; second input was inferred on a flipped image.
    private static func averageWithUnflippedTTA(_ a: [Float], _ flipped: [Float], side: Int) -> [Float] {
        let plane = side * side
        var result = [Float](repeating: 0, count: 3 * plane)
        for c in 0..<3 {
            for y in 0..<side {
                for x in 0..<side {
                    let i = y * side + x
                    let flippedI = y * side + (side - 1 - x)
                    result[c * plane + i] = (a[c * plane + i] + flipped[c * plane + flippedI]) * 0.5
                }
            }
        }
        return result
    }

    private static func argmax(_ probabilities: [Float], side: Int) -> ([UInt8], Double) {
        let plane = side * side
        var mask = [UInt8](repeating: 0, count: plane)
        var confidence = 0.0
        var count = 0
        for i in 0..<plane {
            let p0 = probabilities[i]
            let p1 = probabilities[plane + i]
            let p2 = probabilities[2 * plane + i]
            let cls: UInt8 = (p1 >= p0 && p1 >= p2) ? 1 : ((p2 >= p0 && p2 >= p1) ? 2 : 0)
            mask[i] = cls
            if cls != 0 {
                confidence += Double(max(p0, max(p1, p2)))
                count += 1
            }
        }
        return (mask, count > 0 ? confidence / Double(count) : 0)
    }

    private static func largestComponent(_ source: [Bool], side: Int) -> [Bool] {
        var visited = [Bool](repeating: false, count: source.count)
        var largest = [Int]()
        for start in source.indices where source[start] && !visited[start] {
            var queue = [start], component = [Int](), head = 0
            visited[start] = true
            while head < queue.count {
                let p = queue[head]; head += 1
                component.append(p)
                let x = p % side, y = p / side
                for (nx, ny) in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]
                    where nx >= 0 && nx < side && ny >= 0 && ny < side {
                    let q = ny * side + nx
                    if source[q] && !visited[q] {
                        visited[q] = true
                        queue.append(q)
                    }
                }
            }
            if component.count > largest.count { largest = component }
        }
        var result = [Bool](repeating: false, count: source.count)
        for i in largest { result[i] = true }
        return result
    }

    private static func fillHoles(_ mask: [Bool], side: Int) -> [Bool] {
        var outside = [Bool](repeating: false, count: mask.count)
        var queue = [Int](), head = 0
        for x in 0..<side {
            for p in [x, (side-1)*side+x] where !mask[p] && !outside[p] {
                outside[p] = true; queue.append(p)
            }
        }
        for y in 0..<side {
            for p in [y*side, y*side+side-1] where !mask[p] && !outside[p] {
                outside[p] = true; queue.append(p)
            }
        }
        while head < queue.count {
            let p = queue[head]; head += 1
            let x = p % side, y = p / side
            for (nx, ny) in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]
                where nx >= 0 && nx < side && ny >= 0 && ny < side {
                let q = ny * side + nx
                if !mask[q] && !outside[q] {
                    outside[q] = true; queue.append(q)
                }
            }
        }
        return mask.indices.map { mask[$0] || !outside[$0] }
    }

    private static func postprocess(_ raw: [UInt8], side: Int) -> ([UInt8], [String]) {
        let discRaw = largestComponent(raw.map { $0 >= 1 }, side: side)
        let cupRaw = largestComponent(zip(raw, discRaw).map { $0.0 == 2 && $0.1 }, side: side)
        let disc = fillHoles(discRaw, side: side)
        let cup = zip(fillHoles(cupRaw, side: side), disc).map { $0.0 && $0.1 }
        let discArea = max(1, disc.filter { $0 }.count)
        let cupArea = max(1, cup.filter { $0 }.count)
        let discAdded = zip(disc, discRaw).filter { $0.0 && !$0.1 }.count
        let cupAdded = zip(cup, cupRaw).filter { $0.0 && !$0.1 }.count
        var warnings = [String]()
        if Double(discAdded) / Double(discArea) > 0.08 { warnings.append("OD_HOLE_FILL_EXCESSIVE") }
        if Double(cupAdded) / Double(cupArea) > 0.08 { warnings.append("OC_HOLE_FILL_EXCESSIVE") }
        var touch = 0
        for i in cup.indices where cup[i] {
            let x = i % side, y = i / side
            for (nx, ny) in [(x-1,y),(x+1,y),(x,y-1),(x,y+1),(x-1,y-1),(x+1,y-1),(x-1,y+1),(x+1,y+1)]
                where nx >= 0 && nx < side && ny >= 0 && ny < side {
                if !disc[ny * side + nx] { touch += 1; break }
            }
        }
        if Double(touch) / Double(cupArea) > 0.01 { warnings.append("OC_TOUCHES_BACKGROUND") }
        var out = [UInt8](repeating: 0, count: raw.count)
        for i in out.indices {
            if disc[i] { out[i] = 1 }
            if cup[i] { out[i] = 2 }
        }
        return (out, warnings)
    }

    private static func robustHeight(_ rows: [Int]) -> Double {
        guard rows.count >= 15 else { return 0 }
        let sorted = rows.sorted()
        let low = Int(Double(sorted.count - 1) * 0.02)
        let high = Int(Double(sorted.count - 1) * 0.98)
        return max(1, Double(sorted[high] - sorted[low] + 1))
    }

    private static func makeOverlay(input: UIImage, mask: [UInt8], side: Int) -> UIImage {
        guard let cg = input.cgImage else { return input }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerRow = side * 4
        var rgba = [UInt8](repeating: 255, count: side * side * 4)
        rgba.withUnsafeMutableBytes { raw in
            guard let base = raw.baseAddress,
                  let context = CGContext(data: base, width: side, height: side,
                                          bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                          space: colorSpace,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
            context.draw(cg, in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        for y in 0..<side {
            for x in 0..<side {
                let i = y * side + x
                let cls = mask[i]
                if cls == 0 { continue }
                let boundary = x == 0 || y == 0 || x == side-1 || y == side-1 ||
                    mask[max(0,y-1)*side+x] != cls || mask[min(side-1,y+1)*side+x] != cls ||
                    mask[y*side+max(0,x-1)] != cls || mask[y*side+min(side-1,x+1)] != cls
                if boundary {
                    let j = i * 4
                    if cls == 1 { rgba[j] = 0; rgba[j+1] = 120; rgba[j+2] = 255 }
                    else { rgba[j] = 255; rgba[j+1] = 40; rgba[j+2] = 40 }
                    rgba[j+3] = 255
                }
            }
        }
        let cf = Data(rgba) as CFData
        guard let provider = CGDataProvider(data: cf),
              let out = CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32,
                                bytesPerRow: bytesPerRow, space: colorSpace,
                                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                provider: provider, decode: nil, shouldInterpolate: false,
                                intent: .defaultIntent) else { return input }
        return UIImage(cgImage: out)
    }

    private static func decodeStages(_ raw: [String: Data],
                                     sizes: [String: [NSNumber]]) -> [String: UIImage] {
        let names = [
            "stage1": "1. Original image",
            "stage2": "2. QC correction",
            "stage3": "3. Circular FOV crop",
            "stage4": "4. Optic disc ROI",
            "stage5": "5. Bilateral denoising",
            "stage6": "6. LAB CLAHE",
            "stage7": "7. Final input 512x512"
        ]
        var output = [String: UIImage]()
        for (key, data) in raw {
            guard let title = names[key],
                  let dimensions = sizes[key], dimensions.count == 2 else { continue }
            let width = dimensions[0].intValue
            let height = dimensions[1].intValue
            if let image = Self.imageFromRGBData(data, width: width, height: height) {
                output[title] = image
            }
        }
        return output
    }

    private static func imageFromRGBData(_ data: Data, width: Int, height: Int) -> UIImage? {
        guard width > 0, height > 0, data.count == width * height * 3 else { return nil }
        var rgba = [UInt8](repeating: 255, count: width * height * 4)
        data.withUnsafeBytes { raw in
            guard let src = raw.bindMemory(to: UInt8.self).baseAddress else { return }
            for i in 0..<(width * height) {
                rgba[i*4] = src[i*3]
                rgba[i*4+1] = src[i*3+1]
                rgba[i*4+2] = src[i*3+2]
            }
        }
        let cf = Data(rgba) as CFData
        guard let provider = CGDataProvider(data: cf),
              let cg = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                               bytesPerRow: width*4, space: CGColorSpaceCreateDeviceRGB(),
                               bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                               provider: provider, decode: nil, shouldInterpolate: false,
                               intent: .defaultIntent) else { return nil }
        return UIImage(cgImage: cg)
    }

    private static func doubleMetrics(_ value: Any?) -> [String: Double] {
        guard let raw = value as? [String: NSNumber] else { return [:] }
        return raw.mapValues { $0.doubleValue }
    }

    private static func message(for code: String) -> String {
        let messages = [
            "EMPTY_DISC_MASK": "Model tidak menghasilkan mask optic disc yang valid. Ambil ulang foto.",
            "EMPTY_CUP_MASK": "Model tidak menghasilkan mask optic cup yang valid. Ambil ulang foto.",
            "LOW_SEGMENTATION_CONFIDENCE": "Hasil segmentasi belum cukup meyakinkan. Ambil ulang foto dengan posisi dan fokus yang lebih stabil.",
            "INVALID_SEGMENTATION": "Hasil segmentasi tidak memenuhi pemeriksaan kualitas. Ambil ulang foto."
        ]
        return messages[code] ?? "Foto tidak dapat diproses. Silakan ambil foto fundus ulang."
    }
}

private extension UIImage {
    func normalizedUpright() -> UIImage? {
        if imageOrientation == .up { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: size)) }
    }

    func rgbBytes() -> (Data, Int, Int)? {
        guard let cg = cgImage else { return nil }
        let width = cg.width, height = cg.height
        let bytesPerRow = width * 4
        var rgba = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let context = CGContext(data: &rgba, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        var rgb = [UInt8](repeating: 0, count: width * height * 3)
        for i in 0..<(width * height) {
            rgb[i*3] = rgba[i*4]
            rgb[i*3+1] = rgba[i*4+1]
            rgb[i*3+2] = rgba[i*4+2]
        }
        return (Data(rgb), width, height)
    }
}
