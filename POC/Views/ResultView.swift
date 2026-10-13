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

    private let mint = Color(
        red: 0.66, green: 0.91, blue: 0.83
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Screening result")
                    .font(.largeTitle.bold())

                Text("DEMO — AI NOT CONNECTED")
                    .font(.caption.bold())
                    .tracking(1.2)
                    .foregroundStyle(mint)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 14) {
                    Label("Image received", systemImage: "checkmark.circle")
                        .foregroundStyle(mint)

                    Divider()

                    Text("Segmentation")
                        .font(.headline)
                    Text("Not run — AI integration pending")
                        .foregroundStyle(.secondary)

                    Divider()

                    Text("Vertical cup-to-disc ratio")
                        .font(.headline)
                    Text("Unavailable")
                        .foregroundStyle(.secondary)

                    Divider()

                    Text("Screening interpretation")
                        .font(.headline)
                    Text("No screening result has been generated.")
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                Text(
                    "Research prototype only. This app does not "
                    + "diagnose or rule out glaucoma."
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
}
