//
//  ImageReviewView.swift
//  POC
//

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
        VStack(spacing: 16) {
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

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Color(uiColor: .systemGroupedBackground))
        .preferredColorScheme(.light)
    }

    /*
    private func handleCrop() {
        guard let croppedImage = viewModel.applyCrop(to: image) else { return }
        onUseImage(croppedImage)
    }
    */
}

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
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")

                    Spacer()
                }

                Text("Review")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
            }

            Label(eyeTitle, systemImage: "eye.fill")
                .font(.title3)
                .foregroundStyle(.primary)
        }
    }
}

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
                        side: min(geometry.size.width, geometry.size.height) * 0.72
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            viewModel.resetView()
        }
    }
}

private struct ReviewImageOverlay: View {
    let eyeSide: EyeSide

    var body: some View {
        VStack(alignment: .leading) {
            Text(eyeSide == .left ? "L / OS" : "R / OD")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.8))

            Spacer()

            Text("CAPTURED IMAGE")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(12)
    }
}

private struct CropGuide: View {
    let side: CGFloat

    var body: some View {
        Rectangle()
            .stroke(
                .black,
                style: StrokeStyle(lineWidth: 2, dash: [8, 5])
            )
            .frame(
                width: side,
                height: side
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
    }
}

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 40)
    }
}

private struct ReviewEditingActions: View {
    let isAnalyzing: Bool
    let isLastEye: Bool
    let onRetake: () -> Void
    let onAnalyze: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onRetake) {
                Text("Retake")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.gray.opacity(0.7))
            .foregroundStyle(.white)
            .disabled(isAnalyzing)

            Button(action: onAnalyze) {
                HStack {
                    if isAnalyzing {
                        ProgressView()
                            .tint(.white)
                        Text("Analyzing...")
                    } else {
                        Text(isLastEye ? "Analyze Both Eyes" : "Next")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.28, green: 0.28, blue: 0.29))
            .foregroundStyle(.white)
            .disabled(isAnalyzing)
        }
    }
}

/*
private struct ReviewAnalyzeButton: View {
    let isAnalyzing: Bool
    let isLastEye: Bool
    let onAnalyze: () -> Void

    var body: some View {
        Button(action: onAnalyze) {
            HStack {
                if isAnalyzing {
                    ProgressView()
                        .tint(.white)
                    Text("Analyzing...")
                } else {
                    Text(isLastEye ? "Analyze Both Eyes" : "Next")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(red: 0.28, green: 0.28, blue: 0.29))
        .foregroundStyle(.white)
        .disabled(isAnalyzing)
    }
}
*/