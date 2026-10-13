//
//  ResultView.swift
//  POC
//
//  Created by Harley Ganisson on 13/10/26.
//

import SwiftUI
import UIKit

struct ResultView: View {
    let image: UIImage
    let result: SegmentationResult

    private let mint = Color(
        red: 0.66, green: 0.91, blue: 0.83
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Screening result")
                    .font(.largeTitle.bold())

                Text("MODEL OUTPUT")
                    .font(.caption.bold())
                    .tracking(1.5)
                    .foregroundStyle(mint)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 14) {
                    Text("Vertical cup-to-disc ratio")
                        .font(.headline)

                    if let ratio = result.verticalCDR {
                        Text(ratio, format: .number.precision(
                            .fractionLength(3)
                        ))
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(mint)

                        Text("Calculated from predicted mask heights")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Unavailable")
                            .font(.title2)
                    }

                    Divider()

                    Text("Segmentation summary")
                        .font(.headline)

                    metricRow(
                        title: "Predicted disc region",
                        value: "\(result.discPixelCount) pixels"
                    )

                    metricRow(
                        title: "Predicted cup region",
                        value: "\(result.cupPixelCount) pixels"
                    )

                    metricRow(
                        title: "Mask resolution",
                        value: "\(result.width) × \(result.height)"
                    )
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                Text(
                    "Research POC only. The segmentation classes, "
                    + "preprocessing, and measurements must be "
                    + "validated before clinical interpretation. "
                    + "This output does not diagnose or rule out glaucoma."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(22)
        }
        .background(
            Color(red: 0.055, green: 0.085, blue: 0.105)
                .ignoresSafeArea()
        )
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metricRow(
        title: String,
        value: String
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
    }
}
