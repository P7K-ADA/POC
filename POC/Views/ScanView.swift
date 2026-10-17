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

    @State private var isReviewing = false
    @State private var isAnalyzing = false
    @State private var showResult = false

    @State private var inferenceResult: SegmentationResult?
    @State private var errorMessage: String?

    private let ink = Color(
        red: 0.055, green: 0.085, blue: 0.105
    )
    private let mint = Color(
        red: 0.66, green: 0.91, blue: 0.83
    )

    var body: some View {
        NavigationStack {
            ZStack {
                ink.ignoresSafeArea()

                if isReviewing, let image = selectedImage {
                    ImageReviewView(
                        image: image,
                        selectedItem: $selectedItem,
                        onUseImage: { editedImage in
                            selectedImage = editedImage
                            isReviewing = true
                        },
                        onRetake: {
                            selectedImage = nil
                            selectedItem = nil
                            isReviewing = false
                            camera.start()
                        },
                        onChooseAnother: {
                            selectedItem = nil
                        },
                        onAnalyze: {
                            analyze(image: selectedImage ?? image)
                        },
                        isAnalyzing: isAnalyzing,
                        mint: mint
                    )
                } else {
                    cameraScreen
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showResult) {
                if let image = selectedImage,
                   let result = inferenceResult {
                    ResultView(image: image, result: result)
                }
            }
            .task {
                if !isReviewing {
                    camera.start()
                }
            }
            .onDisappear {
                camera.stop()
            }
            .onChange(of: camera.capturedImage) { _, image in
                guard let image else { return }

                selectedImage = image
                isReviewing = true
                camera.stop()
            }
            .onChange(of: selectedItem) { _, item in
                guard let item else { return }

                Task {
                    await loadGalleryImage(item)
                }
            }
            .alert(
                "Unable to continue",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var cameraScreen: some View {
        VStack(spacing: 22) {
            header

            Text("Position the optic disc inside the frame")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black)

                CameraPreview(session: camera.session)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                ScannerCorners()
                    .stroke(mint, lineWidth: 3)
                    .padding(28)

                VStack {
                    Spacer()
                    Text("CENTER THE OPTIC DISC")
                        .font(.caption2.weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.55))
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                }
            }
            .aspectRatio(3 / 4, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            if !camera.status.isEmpty {
                Text(camera.status)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }

            if let cameraError = camera.errorMessage,
               !cameraError.isEmpty {
                Text(cameraError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 24) {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                        Text("Gallery")
                            .font(.caption)
                    }
                    .foregroundStyle(mint)
                    .frame(width: 76)
                }

                Button {
                    camera.capturePhoto()
                } label: {
                    Circle()
                        .fill(mint)
                        .frame(width: 76, height: 76)
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: 4)
                                .padding(6)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Capture photo")

                Spacer()
                    .frame(width: 76)
            }
            .padding(.top, 4)

            Spacer(minLength: 8)
        }
        .padding(20)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("GlaucoScan")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("Optic disc screening prototype")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "viewfinder")
                .font(.title2)
                .foregroundStyle(mint)
        }
    }

    @MainActor
    private func loadGalleryImage(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Couldn't load that image. Please choose another."
                return
            }

            camera.stop()
            selectedImage = image
            isReviewing = true
        } catch {
            errorMessage = "Couldn't load the selected image: \(error.localizedDescription)"
        }
    }

    private func analyze(image: UIImage) {
        guard !isAnalyzing else { return }

        isAnalyzing = true
        inferenceResult = nil

        Task {
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try ImageInferenceService().predict(image: image)
                }.value

                await MainActor.run {
                    inferenceResult = result
                    isAnalyzing = false
                    showResult = true
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    errorMessage = "Analysis failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
