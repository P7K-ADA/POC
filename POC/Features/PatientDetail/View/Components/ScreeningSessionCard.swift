//
//  ScreeningSessionCard.swift
//  POC
//
//  Created by Carolyn Santana on 20/10/26.
//

import SwiftUI
import UIKit

struct ScreeningSessionCard: View {
    let patient: PatientEntity
    let session: ScreeningSessionEntity
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                EyeEntityThumbnail(
                    examination: examination(for: EyeSide.left.rawValue),
                    title: "Left eye"
                )

                EyeEntityThumbnail(
                    examination: examination(for: EyeSide.right.rawValue),
                    title: "Right eye"
                )
            }

            HStack(alignment: .bottom) {
                Text(
                    session.examDate.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                NavigationLink {
                    ReportOverviewView(
                        patient: patient,
                        session: session,
                        onDone: onDone
                    )
                } label: {
                    Text("View report")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
        }
        .padding()
        .background(
            .background,
            in: RoundedRectangle(cornerRadius: 14)
        )
    }

    private func examination(for side: String) -> EyeExaminationEntity? {
        session.examinations.first { $0.eyeSide == side }
    }
}

private struct EyeEntityThumbnail: View {
    let examination: EyeExaminationEntity?
    let title: String

    private var image: UIImage? {
        guard let path = examination?.originalImagePath,
              !path.isEmpty else {
            return nil
        }

        return LocalFileStorage.shared.loadImage(from: path)
    }

    private var cdr: Float? {
        guard let examination else { return nil }
        guard let analysisRun = examination.analysisRun else { return nil }
        return analysisRun.verticalCDR
    }

    private var segmentationMask: [UInt8]? {
        guard let path = examination?.analysisRun?.segmentationMaskPath,
              !path.isEmpty else {
            return nil
        }

        return LocalFileStorage.shared.loadMask(from: path)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            GeometryReader { geometry in
                ZStack {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                            .clipped()

                        if let segmentationMask,
                           let overlay = SegmentationOverlay.makeImage(
                            from: segmentationMask,
                            width: 512,
                            height: 512
                           ) {
                            Image(uiImage: overlay)
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: geometry.size.width,
                                    height: geometry.size.height
                                )
                                .clipped()
                                .allowsHitTesting(false)
                        }
                    } else {
                        Color.secondary.opacity(0.1)

                        Image(systemName: "eye.slash")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if let cdr {
                Text("CDR \(cdr, specifier: "%.2f")")
                    .font(.caption.weight(.medium))
            } else {
                Text("CDR not detected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
