import SwiftUI
import UIKit

struct ImageReviewView: View {
    let image: UIImage
    let onUseImage: (UIImage) -> Void
    let onRetake: () -> Void

    let isAnalyzing: Bool
    let analysisErrorMessage: String?

    let debugStages: [String: UIImage]
    let debugFailureMessage: String?
    let debugVCDR: Double?
    let debugConfidence: Double?
    let qualityWarnings: [String]

    let eyeSide: EyeSide
    let isLastEye: Bool

    @State private var isShowingQualityAlert = false

    var body: some View {
        ZStack {
            VStack(spacing: Layout.reviewSectionSpacing) {
                ReviewHeader(onBack: onRetake)

                ReviewImageCanvas(
                    image: image,
                    eyeSide: eyeSide
                )

                ReviewStatusCard(
                    analysisErrorMessage: analysisErrorMessage,
                    isAnalyzing: isAnalyzing,
                    qualityWarnings: qualityWarnings
                )

                if !debugStages.isEmpty {
                    NavigationLink {
                        GlaumaDebugGridView(
                            stages: debugStages,
                            failureMessage: debugFailureMessage,
                            vCDR: debugVCDR,
                            confidence: debugConfidence
                        )
                    } label: {
                        Label(
                            "View preprocessing details",
                            systemImage: "square.grid.2x2"
                        )
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppColors.normal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .disabled(isAnalyzing)
                }

                ReviewEditingActions(
                    isAnalyzing: isAnalyzing,
                    hasError: analysisErrorMessage != nil,
                    isLastEye: isLastEye,
                    onRetake: onRetake,
                    onContinue: {
                        if analysisErrorMessage != nil {
                            isShowingQualityAlert = true
                        } else {
                            onUseImage(image)
                        }
                    }
                )

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, Layout.topPadding)
            .padding(.bottom, Layout.reviewBottomPadding)
        }
        .background(AppColors.backgroundSecondary)
        .alert(
            "Foto mungkin tidak terbaca",
            isPresented: $isShowingQualityAlert
        ) {
            Button("Kembali", role: .cancel) {}

            Button("Tetap Lanjut") {
                onUseImage(image)
            }
        } message: {
            Text(
                analysisErrorMessage
                    ?? "Foto ini mungkin tidak dapat dikenali oleh model. Apakah kamu tetap ingin menggunakannya?"
            )
        }
    }
}

#Preview("Review - Ready") {
    ImageReviewView(
        image: ImageReviewPreviewData.image,
        onUseImage: { _ in },
        onRetake: {},
        isAnalyzing: false,
        analysisErrorMessage: nil,
        debugStages: [:],
        debugFailureMessage: nil,
        debugVCDR: nil,
        debugConfidence: nil,
        qualityWarnings: [],
        eyeSide: .left,
        isLastEye: false
    )
    .preferredColorScheme(.dark)
}

#Preview("Review - Error") {
    ImageReviewView(
        image: ImageReviewPreviewData.image,
        onUseImage: { _ in },
        onRetake: {},
        isAnalyzing: false,
        analysisErrorMessage: "Hasil segmentasi belum cukup meyakinkan. Silakan ambil foto ulang.",
        debugStages: [:],
        debugFailureMessage: "Hasil segmentasi belum cukup meyakinkan.",
        debugVCDR: nil,
        debugConfidence: nil,
        qualityWarnings: [],
        eyeSide: .right,
        isLastEye: true
    )
}
