//
//  ImageReviewView.swift
//  POC
//
//  Created by Harley Ganisson on 14/10/26.
//

import SwiftUI
import PhotosUI
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

    @State private var zoom: CGFloat = 1
    @State private var lastZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var cropMode = false
    

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button(action: onRetake) {
                    Label("Retake", systemImage: "arrow.uturn.backward")
                }

                Spacer()

                Text(cropMode ? "Crop image" : "Review image")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    resetView()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel("Reset zoom and position")
            }
            .foregroundStyle(mint)

            Text(
                cropMode
                ? "The square shows the area that will be kept."
                : "Pinch to zoom and drag to reposition the image."
            )
            .font(.caption)
            .foregroundStyle(.white.opacity(0.65))
            .multilineTextAlignment(.center)

            GeometryReader { geometry in
                ZStack {
                    Color.black

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
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

                    if cropMode {
                        Rectangle()
                            .stroke(mint, style: StrokeStyle(
                                lineWidth: 2,
                                dash: [8, 5]
                            ))
                            .frame(
                                width: min(
                                    geometry.size.width,
                                    geometry.size.height
                                ) * 0.72,
                                height: min(
                                    geometry.size.width,
                                    geometry.size.height
                                ) * 0.72
                            )
                            .allowsHitTesting(false)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .aspectRatio(3 / 4, contentMode: .fit)

            HStack(spacing: 12) {
                Button {
                    if cropMode {
                        cropMode = false
                    } else {
                        cropMode = true
                    }
                } label: {
                    Label(
                        cropMode ? "Cancel crop" : "Square crop",
                        systemImage: cropMode ? "xmark" : "crop.rotate"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(mint)
                .disabled(isAnalyzing)

                if cropMode {
                    Button {
                        if let cropped = centerSquareCrop(image) {
                            onUseImage(cropped)
                            cropMode = false
                            resetView()
                        }
                    } label: {
                        Text("Apply crop")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(mint)
                    .foregroundStyle(.black)
                    .disabled(isAnalyzing)
                }
            }

            HStack(spacing: 12) {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Choose another", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(mint)
                .disabled(isAnalyzing)

                Button(action: onAnalyze) {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Image(systemName: "waveform.path.ecg")
                        }

                        Text(isAnalyzing ? "Analyzing…" : "Analyze")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(mint)
                .foregroundStyle(.black)
                .disabled(isAnalyzing)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
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
