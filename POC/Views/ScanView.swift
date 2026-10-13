//
//  ScanView.swift
//  POC
//
//  Created by Harley Ganisson on 13/10/26.
//


import SwiftUI
import PhotosUI
import UIKit

struct ScanView: View {
    @StateObject private var camera = CameraService()

    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var loadError: String?

    @State private var isAnalyzing = false
    @State private var inferenceError: String?
    @State private var inferenceResult: SegmentationResult?
    @State private var showResult = false

    private let ink = Color(
        red: 0.055,
        green: 0.085,
        blue: 0.105
    )

    private let mint = Color(
        red: 0.66,
        green: 0.91,
        blue: 0.83
    )

    var body: some View {
        VStack(spacing: 16) {

            // MARK: Header

            HStack {
                Image(systemName: "eye.circle.fill")
                    .font(.title)
                    .foregroundStyle(mint)

                Spacer()

                VStack(spacing: 3) {
                    Text("GLAUCOSCAN")
                        .font(.caption.bold())
                        .tracking(2)

                    Text("STRUCTURAL SCREENING POC")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(mint)
            }

            // MARK: Instructions

            VStack(spacing: 5) {
                Text(
                    selectedImage == nil
                    ? "Position the optic disc"
                    : "Image ready to analyze"
                )
                .font(.title2.bold())

                Text(
                    selectedImage == nil
                    ? "Keep the image centered and in focus."
                    : "Review your image before continuing."
                )
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
            }

            // MARK: Camera / Image Preview

            ZStack {
                Color.black

                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                } else {
                    CameraPreview(session: camera.session)

                    ScannerCorners()
                        .stroke(
                            mint,
                            style: StrokeStyle(
                                lineWidth: 3,
                                lineCap: .round
                            )
                        )
                        .padding(18)

                    if !camera.isReady {
                        VStack(spacing: 10) {
                            ProgressView()
                                .tint(mint)

                            Text(camera.status)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(.black.opacity(0.7))
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12)
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            // MARK: Errors

            if let message = loadError
                ?? inferenceError
                ?? camera.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            // MARK: Upload and Shutter Controls

            HStack(alignment: .center) {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images
                ) {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 27))
                            .foregroundStyle(mint)
                            .frame(width: 62, height: 62)
                            .background(.white.opacity(0.08))
                            .clipShape(Circle())

                        Text("Upload image")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(width: 100)
                }
                .accessibilityLabel("Upload fundus image")

                Spacer()

                Button {
                    if selectedImage != nil {
                        // Return to the camera for another image.
                        selectedImage = nil
                        inferenceResult = nil
                        inferenceError = nil
                        loadError = nil
                        camera.start()
                    } else {
                        camera.capturePhoto()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 3)
                            .frame(width: 76, height: 76)

                        Circle()
                            .fill(.white)
                            .frame(width: 64, height: 64)
                    }
                }
                .disabled(
                    selectedImage == nil && !camera.isReady
                )
                .accessibilityLabel(
                    selectedImage == nil
                    ? "Capture photo"
                    : "Retake photo"
                )

                Spacer()

                // Balance the shutter button.
                Color.clear
                    .frame(width: 100, height: 62)
            }

            // MARK: One Analyze Button

            Button {
                guard let image = selectedImage,
                      !isAnalyzing else {
                    return
                }

                isAnalyzing = true
                inferenceError = nil
                inferenceResult = nil

                Task {
                    do {
                        let result = try await Task.detached(
                            priority: .userInitiated
                        ) {
                            let service = try ImageInferenceService()
                            return try service.predict(image: image)
                        }.value

                        await MainActor.run {
                            inferenceResult = result
                            isAnalyzing = false
                            showResult = true
                        }
                    } catch {
                        await MainActor.run {
                            inferenceError =
                                error.localizedDescription
                            isAnalyzing = false
                        }
                    }
                }
            } label: {
                HStack {
                    if isAnalyzing {
                        ProgressView()
                            .tint(ink)
                    }

                    Text(
                        isAnalyzing
                        ? "Analyzing..."
                        : "Analyze image"
                    )

                    Spacer()

                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundStyle(ink)
                .padding(17)
                .frame(maxWidth: .infinity)
                .background(
                    selectedImage == nil
                    ? mint.opacity(0.4)
                    : mint
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 15)
                )
            }
            .disabled(
                selectedImage == nil || isAnalyzing
            )

            Text(
                "Research prototype · AI-generated measurements "
                + "require validation"
            )
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.4))
            .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(ink.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)

        // MARK: Results Navigation

        .navigationDestination(isPresented: $showResult) {
            if let image = selectedImage,
               let result = inferenceResult {
                ResultView(
                    image: image,
                    result: result
                )
            }
        }

        // MARK: Camera Lifecycle

        .task {
            camera.start()
        }
        .onDisappear {
            camera.stop()
        }

        // MARK: Captured Image

        .onChange(of: camera.capturedImage) { _, image in
            if let image {
                selectedImage = image
                loadError = nil
                inferenceError = nil
                inferenceResult = nil
                camera.stop()
            }
        }

        // MARK: Uploaded Image

        .onChange(of: selectedItem) { _, item in
            Task {
                await loadImage(from: item)
            }
        }
    }

    // MARK: Load Selected Image

    @MainActor
    private func loadImage(
        from item: PhotosPickerItem?
    ) async {
        guard let item else { return }

        loadError = nil
        inferenceError = nil

        do {
            guard let data = try await item.loadTransferable(
                type: Data.self
            ) else {
                loadError = "Could not read the selected image."
                return
            }

            guard let image = UIImage(data: data) else {
                loadError = "Unsupported image format."
                return
            }

            selectedImage = image
            inferenceResult = nil
            camera.stop()

        } catch {
            loadError =
                "Image import failed. Please try again."
        }
    }
}
