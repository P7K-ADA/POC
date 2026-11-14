//
//  PreprocessingDetailsSection.swift
//  POC
//
//  Created by Carolyn Santana on 14/11/26.
//

import SwiftUI

struct PreprocessingDetailsSection: View {
    let report: ReportData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preprocessing Details")
                .font(.headline)

            Text("Explore the image processing stages for each eye.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            eyeButton(title: "Left Eye", eye: report.left)
            eyeButton(title: "Right Eye", eye: report.right)
        }
    }

    @ViewBuilder
    private func eyeButton(
        title: String,
        eye: EyeReport
    ) -> some View {
        if !eye.debugStages.isEmpty {
            NavigationLink {
                GlaumaDebugGridView(
                    stages: eye.debugStages,
                    failureMessage: nil,
                    vCDR: eye.cdr,
                    confidence: eye.confidence
                )
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.grid.2x2")
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("View \(title) Processing Stages")
                            .font(.subheadline.weight(.medium))

                        Text("Explore all available processing stages")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.primary)
                .padding()
                .background(
                    AppColors.white,
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
            .buttonStyle(.plain)
        }
    }
}
