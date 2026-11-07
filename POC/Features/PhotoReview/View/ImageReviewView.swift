
import PhotosUI
import SwiftUI
import UIKit

struct ImageReviewView: View {
    let image: UIImage
    @Binding var selectedItem: PhotosPickerItem?

    let onUseImage: (UIImage) -> Void
    let onRetake: () -> Void
    let onChooseAnother: () -> Void
    let onAnalyze: () -> Void

    let isAnalyzing: Bool
    let mint: Color
    let eyeSide: EyeSide
    let isLastEye: Bool

    @StateObject private var viewModel = ImageReviewViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                ReviewHeader(
                    eyeTitle: eyeSide == .left ? "Left eye" : "Right eye",
                    onBack: onRetake
                )

                ReviewImageCanvas(
                    image: image,
                    eyeSide: eyeSide,
                    viewModel: viewModel
                )

                ReviewGuidance(isLastEye: isLastEye)

                ReviewEditingActions(
                    isAnalyzing: isAnalyzing,
                    isLastEye: isLastEye,
                    onRetake: onRetake,
                    onAnalyze: onAnalyze
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .preferredColorScheme(.light)
    }
}

// MARK: - Header

private struct ReviewHeader: View {
    let eyeTitle: String
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.title2.weight(.medium))
                            .frame(minWidth: 44, minHeight: 44)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                    .accessibilityHint(
                        "Returns to the camera to retake the image."
                    )

                    Spacer()
                }

                Text("Review")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
            }

            Label(eyeTitle, systemImage: "eye.fill")
                .font(.title3)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Image Canvas

private struct ReviewImageCanvas: View {
    let image: UIImage
    let eyeSide: EyeSide

    @ObservedObject var viewModel: ImageReviewViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color(red: 0.16, green: 0.16, blue: 0.17)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(viewModel.zoom)
                    .offset(viewModel.offset)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
                    .gesture(
                        MagnificationGesture()
                            .onChanged(viewModel.updateZoom(with:))
                            .onEnded { _ in
                                viewModel.finishZoom()
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                viewModel.updateOffset(
                                    with: value.translation
                                )
                            }
                            .onEnded { _ in
                                viewModel.finishDrag()
                            }
                    )

                ReviewImageOverlay(eyeSide: eyeSide)

                if viewModel.cropMode {
                    CropGuide(
                        side: min(
                            geometry.size.width,
                            geometry.size.height
                        ) * 0.72
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Preview of image")
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .onAppear {
            viewModel.resetView()
        }
    }
}

// MARK: - Image Overlay

private struct ReviewImageOverlay: View {
    let eyeSide: EyeSide

    var body: some View {
        VStack(alignment: .leading) {
            Text(eyeSide == .left ? "L / OS" : "R / OD")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.8))

            Spacer()

            Text("CAPTURED IMAGE")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(12)
        .accessibilityHidden(true)
    }
}

// MARK: - Crop Guide

private struct CropGuide: View {
    let side: CGFloat

    var body: some View {
        Rectangle()
            .stroke(
                .black,
                style: StrokeStyle(lineWidth: 2, dash: [8, 5])
            )
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Guidance

private struct ReviewGuidance: View {
    let isLastEye: Bool

    var body: some View {
        Text(
            isLastEye
            ? "Overview can only be generated after both eyes have been scanned."
            : "Review the image before continuing to the other eye."
        )
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

// MARK: - Editing Actions

private struct ReviewEditingActions: View {
    let isAnalyzing: Bool
    let isLastEye: Bool
    let onRetake: () -> Void
    let onAnalyze: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {

            // Side-by-side buttons when there is enough room
            HStack(spacing: 12) {
                retakeButton
                analyzeButton
            }

            // Stacked buttons when text becomes larger
            VStack(spacing: 12) {
                retakeButton
                analyzeButton
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var retakeButton: some View {
        Button(action: onRetake) {
            Text("Retake")
                .font(.body.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
        }
        .buttonStyle(.borderedProminent)
        .tint(.gray.opacity(0.7))
        .foregroundStyle(.white)
        .disabled(isAnalyzing)
        .accessibilityLabel("Retake")
        .accessibilityHint(
            "Returns to the camera to capture this eye again."
        )
    }

    private var analyzeButton: some View {
        Button(action: onAnalyze) {
            HStack(spacing: 8) {
                if isAnalyzing {
                    ProgressView()
                        .tint(.white)
                        .accessibilityHidden(true)
                }

                Text(
                    isAnalyzing
                    ? "Analyzing..."
                    : (isLastEye ? "Analyze Both Eyes" : "Next")
                )
                .font(.body.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(red: 0.28, green: 0.28, blue: 0.29))
        .foregroundStyle(.white)
        .disabled(isAnalyzing)
        .accessibilityLabel(
            isAnalyzing
            ? "Analyzing"
            : (isLastEye ? "Analyze both eyes" : "Next")
        )
        .accessibilityHint(
            isAnalyzing
            ? "Image analysis is in progress."
            : (isLastEye
                ? "Analyzes the images of both eyes."
                : "Continue to capture the other eye.")
        )
    }
}
