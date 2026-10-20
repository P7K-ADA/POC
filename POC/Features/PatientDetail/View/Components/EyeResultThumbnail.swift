//
//  EyeResultThumbnail.swift
//  POC
//
//  Created by Carolyn Santana on 20/10/26.
//



import SwiftUI

struct EyeResultThumbnail: View {
    let eye: EyeExaminationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eye.eyeSide.rawValue)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Text(cdrDescription)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .foregroundStyle(.secondary)

            Group {
                if let image = eye.image {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()

                        if let result = eye.segmentationResult,
                           let overlay = SegmentationOverlay.makeImage(
                               from: result
                           ) {
                            Image(uiImage: overlay)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
                    .background(.black)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(height: 110)
                        .overlay {
                            Image(systemName: "eye")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                }
            }

            if eye.isDummy {
                Text("Placeholder")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cdrDescription: String {
        guard let cdr = eye.verticalCDR else {
            return "CDR not detected"
        }

        return String(format: "CDR (%.2f)", cdr)
    }
}
