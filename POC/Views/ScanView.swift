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

    private let ink = Color(
        red: 0.055, green: 0.085, blue: 0.105
    )
    private let mint = Color(
        red: 0.66, green: 0.91, blue: 0.83
    )

    var body: some View {
        VStack(spacing: 16) {
            // Header
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

            VStack(spacing: 5) {
                Text("Position the optic disc")
                    .font(.title2.bold())
                Text("Keep the image centered and in focus.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .multilineTextAlignment(.center)

            // Live camera, or a captured/uploaded image
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
                        }
                        .padding()
                        .background(.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            if let message = loadError ?? camera.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // Upload icon and shutter
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
                        selectedImage = nil
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
                .disabled(selectedImage == nil && !camera.isReady)
                .accessibilityLabel(
                    selectedImage == nil ? "Capture photo" : "Retake photo"
                )

                Spacer()

                Color.clear
                    .frame(width: 100, height: 62)
            }

            if let selectedImage {
                NavigationLink {
                    ResultView(image: selectedImage)
                } label: {
                    HStack {
                        Text("Analyze image")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundStyle(ink)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(mint)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            } else {
                Text("Capture or upload an image to continue.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(20)
        .background(ink.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            camera.start()
        }
        .onChange(of: camera.capturedImage) { _, image in
            if let image {
                selectedImage = image
                loadError = nil
            }
        }
        .onChange(of: selectedItem) { _, item in
            Task {
                await loadImage(from: item)
            }
        }
        .onDisappear {
            camera.stop()
        }
    }

    @MainActor
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        loadError = nil

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
            camera.stop()
        } catch {
            loadError = "Image import failed. Please try again."
        }
    }
}
