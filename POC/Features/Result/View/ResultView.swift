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

    @Environment(\.dismiss) private var dismiss

    private let mint = Color(
        red: 0.66, green: 0.91, blue: 0.83
    )

    var body: some View {
        ZStack {
            Color(
                red: 0.055, green: 0.085, blue: 0.105
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                        .foregroundStyle(mint)

                        Spacer()

                        Text("Analysis result")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Spacer()

                        // Balances the Back button.
                        Image(systemName: "chevron.left")
                            .opacity(0)
                    }

                    Text("Segmentation preview")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()

                        if let overlay = SegmentationOverlay.makeImage(
                            from: result
                        ) {
                            Image(uiImage: overlay)
                                .resizable()
                                .scaledToFit()
                                .allowsHitTesting(false)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    }

                    HStack(spacing: 18) {
                        legend(color: Color(
                            red: 0.18, green: 0.86, blue: 0.53
                        ), title: "Optic disc")

                        legend(color: Color(
                            red: 1, green: 0.29, blue: 0.33
                        ), title: "Optic cup")
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Measurements")
                            .font(.headline)
                            .foregroundStyle(.white)

                        measurementRow(
                            title: "Vertical cup-to-disc ratio",
                            value: result.verticalCDR.map {
                                String(format: "%.3f", $0)
                            } ?? "N/A"                        )

                        Divider()
                            .overlay(.white.opacity(0.12))

                        measurementRow(
                            title: "Disc pixels",
                            value: "\(result.discPixelCount)"
                        )

                        Divider()
                            .overlay(.white.opacity(0.12))

                        measurementRow(
                            title: "Cup pixels",
                            value: "\(result.cupPixelCount)"
                        )
                    }
                    .padding(18)
                    .background(.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    Text(
                        "Research prototype only. Segmentation boundaries " +
                        "and the calculated ratio have not been clinically " +
                        "validated. This result is not a glaucoma diagnosis."
                    )
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)

                    Button {
                        dismiss()
                    } label: {
                        Text("Back to image review")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(mint)
                    .foregroundStyle(.black)
                }
                .padding(20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private func legend(color: Color, title: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private func measurementRow(
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.white.opacity(0.75))

            Spacer()

            Text(value)
                .font(.title3.monospacedDigit().bold())
                .foregroundStyle(.white)
        }
    }
}
