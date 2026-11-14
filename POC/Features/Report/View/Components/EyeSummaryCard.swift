//
//  EyeSummaryCard.swift
//  POC
//

import SwiftUI

struct EyeSummaryCard: View {
    let eye: EyeReport
    var showsDetailsLink = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(eye.side == .left ? "Mata Kiri" : "Mata Kanan")
                Spacer()
                Text(eye.side == .left ? "OS" : "OD")
                    .foregroundStyle(.secondary)
            }
            .font(.headline)

            SegmentationImageView(
                side: eye.side,
                image: eye.image,
                segmentationReferenceImage: eye.segmentationReferenceImage,
                segmentationMask: eye.segmentationMask,
                maskWidth: eye.maskWidth,
                maskHeight: eye.maskHeight
            )
            .accessibilityHidden(true)

            HStack(alignment: .firstTextBaseline) {
                Text("vCDR")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(eye.cdrText)
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(eye.status.tint)
            }

            if showsDetailsLink {
                Divider()
                    .padding(.top, 2)

                HStack(spacing: 2) {
                    Text("Lihat detail")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.footnote)
                .foregroundStyle(AppColors.labelSecondary)
            }
        }
        .reportCard()
    }
}
