//
//  ImageReviewView.swift
//  POC
//
//  Created by Harley Ganisson on 14/10/26.
//

import SwiftUI
import PhotosUI
import UIKit

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

    @State private var zoom: CGFloat = 1
    @State private var lastZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var cropMode = false
    

    var body: some View {
        VStack(spacing: 16) {
            ReviewHeader(
                eyeTitle: eyeSide == .left ? "Left eye" : "Right eye",
                onBack: onRetake
            )

            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    Color(red: 0.16, green: 0.16, blue: 0.17)

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(zoom)
                        .offset(offset)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    zoom = min(max(lastZoom * value, 1), 5)
                                }
                                .onEnded { _ in
                                    lastZoom = zoom
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )

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

                    if cropMode {
                        Rectangle()
                            .stroke(
                                Color.black,
                                style: StrokeStyle(lineWidth: 2, dash: [8, 5])
                            )
                            .frame(
                                width: min(geometry.size.width, geometry.size.height) * 0.72,
                                height: min(geometry.size.width, geometry.size.height) * 0.72
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .allowsHitTesting(false)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .aspectRatio(1, contentMode: .fit)

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

            HStack(spacing: 12) {
                Button(action: onRetake) {
                    Text("Retake")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.gray.opacity(0.7))
                .foregroundStyle(.white)
                .disabled(isAnalyzing)

                Button {
                    if cropMode {
                        if let cropped = centerSquareCrop(image) {
                            onUseImage(cropped)
                            cropMode = false
                            resetView()
                        }
                    } else {
                        cropMode = true
                    }
                } label: {
                    Text(cropMode ? "Apply crop" : "Crop")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.gray.opacity(0.7))
                .foregroundStyle(.white)
                .disabled(isAnalyzing)
            }

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

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Color(uiColor: .systemGroupedBackground))
        .preferredColorScheme(.light)
    }

    private func resetView() {
        zoom = 1
        lastZoom = 1
        offset = .zero
        lastOffset = .zero
    }

    private func centerSquareCrop(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let side = min(cgImage.width, cgImage.height)
        let rect = CGRect(
            x: (cgImage.width - side) / 2,
            y: (cgImage.height - side) / 2,
            width: side,
            height: side
        )

        guard let cropped = cgImage.cropping(to: rect) else {
            return nil
        }

        return UIImage(
            cgImage: cropped,
            scale: image.scale,
            orientation: image.imageOrientation
        )
    }
}
