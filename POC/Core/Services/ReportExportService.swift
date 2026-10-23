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
        case overview
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
                view: SingleReportExportPage(report: report)
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



struct SingleReportExportPage: View {
    let report: ReportData

    var body: some View {
        VStack(spacing: 0) {
            // BAGIAN ATAS (Hitam): Dua Foto Retina Berdampingan
            HStack(spacing: 0) {
                eyePhotoCell(eye: report.left)
                eyePhotoCell(eye: report.right)
            }
            .background(Color.black)

            // BAGIAN BAWAH (Abu-Abu): Banner AI DISCLAIMER
            VStack(alignment: .leading, spacing: 6) {
                Text("AI DISCLAIMER")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Color.black)

                Text("\(ReportCopy.cdrExplainer) \(ReportCopy.aiDisclaimer)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.86, green: 0.86, blue: 0.86))
        }
        .frame(width: 700) // Lebar kanvas (akan di-render 3x lebih tajam untuk JPG)
        .environment(\.colorScheme, .light)
    }

    @ViewBuilder
    private func eyePhotoCell(eye: EyeReport) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let image = eye.image {
                ZStack {
                    // Foto retina asli
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()

                    // Garis overlay AI (Disc & Cup)
                    if let mask = eye.segmentationMask,
                       let overlay = SegmentationOverlay.makeImage(
                        from: mask,
                        width: eye.maskWidth,
                        height: eye.maskHeight
                       ) {
                        Image(uiImage: overlay)
                            .resizable()
                            .scaledToFill()
                    }
                }
                .aspectRatio(1.0, contentMode: .fit)
                .clipped()
            } else {
                Color.black
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay {
                        Text("No Image")
                            .font(.headline)
                            .foregroundStyle(.gray)
                    }
            }

            // Teks CDR di pojok kiri bawah persis seperti gambar referensi
            Text("CDR : \(eye.cdrText)")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white)
                .padding(16)
                .shadow(color: .black.opacity(0.85), radius: 4, x: 2, y: 2)
        }
    }
}
