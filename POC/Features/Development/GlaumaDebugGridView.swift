import SwiftUI
import UIKit

struct GlaumaDebugGridView: View {
    let stages: [String: UIImage]
    let failureMessage: String?
    let vCDR: Double?
    let confidence: Double?

    private let orderedTitles = [
        "1. Original image",
        "2. QC correction",
        "3. Circular FOV crop",
        "4. Optic disc ROI",
        "5. Bilateral denoising",
        "6. LAB CLAHE",
        "7. Final input 512x512",
        "8. Segmentation overlay"
    ]

    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(orderedTitles, id: \.self) { title in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.caption.weight(.semibold))
                            .multilineTextAlignment(.leading)
                        if let image = stages[title] {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .background(Color.black.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else if title == "8. Segmentation overlay", let failureMessage {
                            Text(failureMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, minHeight: 150, alignment: .center)
                                .padding(8)
                                .background(Color.red.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Text("Belum tersedia")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 150)
                                .background(Color.secondary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding()
            if let vCDR {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "vCDR: %.3f", vCDR))
                    if let confidence {
                        Text(String(format: "Model confidence score: %.2f", confidence))
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Fundus preprocessing")
    }
}
