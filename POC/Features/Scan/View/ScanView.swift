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
    @Environment(\.dismiss) private var dismiss

    // MARK: - Patient Context

    let patient: PatientEntity
    let onSaveSession: (ScreeningSession) -> Void
    let onDone: () -> Void

    init(
        patient: PatientEntity,
        onSaveSession: @escaping (ScreeningSession) -> Void,
        onDone: @escaping () -> Void = {}
    ) {
        self.patient = patient
        self.onSaveSession = onSaveSession
        self.onDone = onDone
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
    @State private var completedSession: ScreeningSession?
    @State private var showReport = false
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

    private let ink = Color(uiColor: .systemGroupedBackground)

    private let mint = Color.white

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

            // MARK: - Report Navigation

            .navigationDestination(isPresented: $showReport) {
                if let completedSession {
                    ReportOverviewView(
                        patient: patient,
                        session: completedSession,
                        onDone: onDone
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
        .preferredColorScheme(.light)
    }

    // MARK: - Camera Screen

    private var cameraScreen: some View {
        VStack(spacing: 18) {
            header
            
            /*
            EyeSelectorBar(
                selectedEye: $selectedEye,
                isRightCaptured: rightImage != nil,
                isLeftCaptured: leftImage != nil,
                mintColor: mint
            )
            .padding(.horizontal, 4)
            */

            GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black)
                
                CameraPreview(session: camera.session)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 24)
                    )
                
                Circle()
                    .stroke(
                        Color.black.opacity(0.85),
                        style: StrokeStyle(lineWidth: 1, dash: [10, 10])
                    )
                    .frame(width: 240, height: 240)
                
                if let point = focusPoint {
                    FocusSquareView(color: mint)
                        .position(point)
                        .id(focusID)
                }
                
                VStack {
                    Spacer()
                    
                    Text("ALIGN EYE TO TARGET")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                        }
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
            .aspectRatio(6 / 7, contentMode: .fit)
            .clipShape(
                RoundedRectangle(cornerRadius: 24)
            )

            if !camera.status.isEmpty {
                Text(camera.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let cameraError = camera.errorMessage,
               !cameraError.isEmpty {
                Text(cameraError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Text("1x")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                
                Slider(
                    value: Binding(
                        get: {camera.currentZoomFactor},
                        set: {camera.setZoom(factor: $0)}
                    ),
                    in: 1...4
                )
                .tint(.black)
                
                Text("4x")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            
            
            // Gallery and secondary actions are intentionally hidden for this camera pass.
            HStack {
                Button {
                    camera.capturePhoto()
                } label: {
                    Circle()
                        .fill(mint)
                        .frame(width: 76, height: 76)
                        .overlay {
                            Circle()
                                .stroke(.black, lineWidth: 4)
                                .padding(6)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Capture photo")

            }
            .padding(.top, 4)

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()

                // Help and other secondary functions are intentionally hidden for now.
            }

            Text(selectedEye == .left ? "Left Eye" : "Right Eye")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Reset Scan

    private func resetScan() {
        selectedImage = nil
        selectedItem = nil
        isReviewing = false
        showReport = false
        completedSession = nil
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
                    self.saveCurrentSession()
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
            patientID: patient.id,
            examDate: .now,
            status: .completed,
            leftEye: leftEye,
            rightEye: rightEye
        )

        // Persist the completed session, then show the combined report.
        onSaveSession(session)
        completedSession = session
        showReport = true
    }
}
