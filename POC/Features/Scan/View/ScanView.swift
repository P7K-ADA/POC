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
    // MARK: - Patient Context

    let patientID: UUID
    let onSaveSession: (ScreeningSession) -> Void

    init(
        patientID: UUID,
        onSaveSession: @escaping (ScreeningSession) -> Void
    ) {
        self.patientID = patientID
        self.onSaveSession = onSaveSession
    }

    // MARK: - Camera

    @StateObject private var camera = CameraService()

    // MARK: - Image State

    @State private var selectedEye: EyeSide = .left
    @State private var rightImage: UIImage?
    @State private var leftImage: UIImage?
    @State private var rightResult: SegmentationResult?
    @State private var leftResult: SegmentationResult?
    
    @State private var focusPoint: CGPoint?
    @State private var focusID = UUID()
    @State private var baseZoom: CGFloat = 1.0
    
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isReviewing = false
    @State private var isAnalyzing = false
    @State private var showResult = false
    @State private var errorMessage: String?
    
    private var isLastEye: Bool {
        if selectedEye == .right {
            return leftImage != nil
        }
        else{
            return rightImage != nil
        }
    }
    

    // MARK: - Colors

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

    // MARK: - Body

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
                            if selectedEye == .right {rightImage = nil} else {leftImage = nil}
                            selectedImage = nil
                            isReviewing = false
                            camera.start()
                        },
                        onChooseAnother: {
                            selectedItem = nil
                        },
                        onAnalyze: {
                            handleConfirmOrAnalyze(image: image)
                        },
                        isAnalyzing: isAnalyzing,
                        mint: mint,
                        eyeSide: selectedEye,
                        isLastEye: isLastEye
                    )
                } else {
                    cameraScreen
                }
            }
            .toolbar(.hidden, for: .navigationBar)

            // MARK: - Result Navigation

            .navigationDestination(isPresented: $showResult) {
                if let image = rightImage ?? leftImage ?? selectedImage,
                   let result = rightResult ?? leftResult
                    {
                    ResultView(
                        image: image,
                        result: result,
                        onSave: saveCurrentSession
                    )
                }
            }

            // MARK: - Camera Lifecycle

            .task {
                if !isReviewing {
                    camera.start()
                }
            }
            .onDisappear {
                camera.stop()
            }

            // MARK: - Captured Image

            .onChange(of: camera.capturedImage) { _, image in
                guard let image else { return }

                selectedImage = image
                selectedItem = nil
                isReviewing = true
                camera.stop()
            }

            // MARK: - Gallery Selection

            .onChange(of: selectedItem) { _, item in
                guard let item else { return }

                Task {
                    await loadGalleryImage(item)
                }
            }

            // MARK: - Error Alert

            .alert(
                "Unable to continue",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: {
                        if !$0 {
                            errorMessage = nil
                        }
                    }
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

    // MARK: - Camera Screen

    private var cameraScreen: some View {
        VStack(spacing: 22) {
            header
            
            EyeSelectorBar(
                selectedEye: $selectedEye,
                isRightCaptured: rightImage != nil,
                isLeftCaptured: leftImage != nil,
                mintColor: mint
            )
            .padding(.horizontal, 4)
            
            Text("Position \(selectedEye.rawValue.lowercased()) inside the frame")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black)
                
                CameraPreview(session: camera.session)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 24)
                    )
                
                ScannerCorners()
                    .stroke(mint, lineWidth: 3)
                    .padding(28)
                
                if let point = focusPoint {
                    FocusSquareView(color: mint)
                        .position(point)
                        .id(focusID)
                }
                
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
            .contentShape(Rectangle())
            .onTapGesture {
                location in
                focusPoint = location
                focusID = UUID()
                
                let deviceX = location.y / geo.size.height
                let deviceY = 1.0 - (location.x / geo.size.width)
                camera.focus(at: CGPoint(x: deviceX, y: deviceY))
            }
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let newZoom = baseZoom * value
                        camera.setZoom(factor: newZoom)
                    }
                    .onEnded { _ in
                        baseZoom = camera.currentZoomFactor
                    }
            )
        }
            .aspectRatio(3 / 4, contentMode: .fit)
            .clipShape(
                RoundedRectangle(cornerRadius: 24)
            )

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

            HStack(spacing: 12){
                ForEach([1.0, 2.0], id: \.self) {
                    factor in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            camera.setZoom(factor: factor)
                            baseZoom = factor
                        }
                    }
                    label: {
                        Text("\(Int (factor))x")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(camera.currentZoomFactor == factor ? Color.black : Color.white)
                            .frame(width: 34, height: 34)
                            .background(camera.currentZoomFactor == factor ? mint : Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.bottom, 8)
            
            
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

    // MARK: - Header

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

    // MARK: - Reset Scan

    private func resetScan() {
        selectedImage = nil
        selectedItem = nil
        isReviewing = false
        showResult = false
    }

    // MARK: - Load Gallery Image

    @MainActor
    private func loadGalleryImage(
        _ item: PhotosPickerItem
    ) async {
        do {
            guard
                let data = try await item.loadTransferable(
                    type: Data.self
                ),
                let image = UIImage(data: data)
            else {
                errorMessage =
                    "Couldn't load that image. Please choose another."
                return
            }

            camera.stop()
            selectedImage = image
            isReviewing = true
        } catch {
            errorMessage =
                "Couldn't load the selected image: " +
                error.localizedDescription
        }
    }
    // MARK: - Handle Confirmation & Sequencing
    
    private func handleConfirmOrAnalyze(image: UIImage){
        if selectedEye == .right {
                    rightImage = image
                } else {
                    leftImage = image
                }
        if !isLastEye {
            selectedEye = (selectedEye == .right) ? .left : .right
            selectedImage = nil
            isReviewing = false
            camera.start()
        }
        else{
            analyzeBothEyes()
        }
    }
    // MARK: - Analyze Image

    private func analyzeBothEyes() {
        guard !isAnalyzing else { return }

        isAnalyzing = true
        

        Task {
            do {
                let service = try ImageInferenceService()
                var rRes: SegmentationResult?
                var lRes: SegmentationResult?
                
                if let rImg = rightImage {rRes = try service.predict(image: rImg)}
                if let lImg = leftImage { lRes = try service.predict(image: lImg)}

                await MainActor.run {
                    self.rightResult = rRes
                    self.leftResult = lRes
                    self.isAnalyzing = false
                    self.showResult = true
                }
            } catch {
                await MainActor.run {
                    self.isAnalyzing = false
                    self.errorMessage =
                        "Analysis failed: \(error.localizedDescription)"
                        
                }
            }
        }
    }

    // MARK: - Save Screening Session

    private func saveCurrentSession() {
        
        let sessionID = UUID()

        // Current POC: actual scan is assigned to the left eye.
        let leftEye = EyeExaminationRecord(
            sessionID: sessionID,
            eyeSide: .left,
            image: leftImage,
            segmentationResult: leftResult,
            isDummy: leftImage == nil
        )

        // Temporary placeholder until right-eye scanning is implemented.
        let rightEye = EyeExaminationRecord(
            sessionID: sessionID,
            eyeSide: .right,
            image: rightImage,
            segmentationResult: rightResult,
            isDummy: rightImage == nil
        )

        let session = ScreeningSession(
            id: sessionID,
            patientID: patientID,
            examDate: .now,
            status: .completed,
            leftEye: leftEye,
            rightEye: rightEye
        )

        // Patient Detail handles persistence and dismisses the scanner.
        onSaveSession(session)
    }
}
