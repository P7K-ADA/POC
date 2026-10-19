//
//  ReportExportService.swift
//  POC
//
//  Created by Harley Ganisson on 20/10/26.
//

import SwiftUI
import Photos
import UniformTypeIdentifiers

struct ExportItem: Identifiable {
    enum Kind: String, CaseIterable {
        case overview, leftEye, rightEye
    }

    let kind: Kind
    let title: String
    let detail: String
    let filename: String
    let image: UIImage
    let jpegData: Data

    var id: Kind { kind }
}

enum ReportExportError: LocalizedError {
    case renderFailed
    case photosAccessDenied

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            return "The report image could not be created."
        case .photosAccessDenied:
            return "Photos access was denied. Allow \"Add Photos Only\" for GlaucoScan in Settings."
        }
    }
}

@MainActor
enum ReportExportService {
    static func render(_ report: ReportData) throws -> [ExportItem] {
        [
            try makeItem(
                kind: .overview,
                title: "Overview",
                detail: "overview.jpg · Both eyes + CDR values",
                filename: "overview.jpg",
                view: OverviewExportPage(report: report)
            ),
            try makeItem(
                kind: .leftEye,
                title: EyeSide.left.rawValue,
                detail: "left_eye.jpg · CDR \(report.left.cdrText) · \(report.left.status.label)",
                filename: "left_eye.jpg",
                view: EyeExportPage(report: report, side: .left)
            ),
            try makeItem(
                kind: .rightEye,
                title: EyeSide.right.rawValue,
                detail: "right_eye.jpg · CDR \(report.right.cdrText) · \(report.right.status.label)",
                filename: "right_eye.jpg",
                view: EyeExportPage(report: report, side: .right)
            )
        ]
    }

    static func saveToPhotos(_ items: [ExportItem]) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ReportExportError.photosAccessDenied
        }

        let files = items.map { (name: $0.filename, data: $0.jpegData) }

        try await PHPhotoLibrary.shared().performChanges {
            for file in files {
                let options = PHAssetResourceCreationOptions()
                options.originalFilename = file.name
                options.uniformTypeIdentifier = UTType.jpeg.identifier
                PHAssetCreationRequest.forAsset()
                    .addResource(with: .photo, data: file.data, options: options)
            }
        }
    }

    private static func makeItem<V: View>(
        kind: ExportItem.Kind,
        title: String,
        detail: String,
        filename: String,
        view: V
    ) throws -> ExportItem {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        renderer.isOpaque = true

        guard let image = renderer.uiImage,
              let data = image.jpegData(compressionQuality: 0.92) else {
            throw ReportExportError.renderFailed
        }

        return ExportItem(
            kind: kind,
            title: title,
            detail: detail,
            filename: filename,
            image: image,
            jpegData: data
        )
    }
}
