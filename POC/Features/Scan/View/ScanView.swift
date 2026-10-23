//
//  ScanView.swift
//  POC
//

import SwiftUI

struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()

    private let pageBackground = Color(uiColor: .systemGroupedBackground)
    private let tint = Color.white

    var body: some View {
        NavigationStack {
            ZStack {
                pageBackground
                    .ignoresSafeArea()

                content
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $viewModel.showReport) {
                reportDestination
            }
            .onDisappear {
                viewModel.stopCamera()
            }
            .onChange(of: viewModel.selectedItem) { _, item in
                guard let item else { return }

                Task {
                    await viewModel.loadGalleryImage(item)
                }
            }
            .alert(
                "Unable to continue",
                isPresented: errorAlertBinding
            ) {
                Button("OK", role: .cancel) {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "Please try again.")
            }
        }
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isReviewing, let image = viewModel.selectedImage {
            ImageReviewView(
                image: image,
                selectedItem: $viewModel.selectedItem,
                onUseImage: viewModel.useEditedImage,
                onRetake: viewModel.retakeCurrentEye,
                onChooseAnother: viewModel.chooseAnotherImage,
                onAnalyze: {
                    Task {
                        await viewModel.analyzeCurrentImage()
                    }
                },
                isAnalyzing: viewModel.isAnalyzing,
                mint: tint,
                eyeSide: viewModel.selectedEye,
                isLastEye: viewModel.isLastEye
            )
        } else {
            ScanCameraView(
                camera: viewModel.camera,
                selectedEye: viewModel.selectedEye,
                tint: tint,
                onCapturedImage: viewModel.handleCapturedImage
            )
        }
    }

    @ViewBuilder
    private var reportDestination: some View {
        if let session = viewModel.completedSession {
            ReportOverviewView(
                report: ReportData.make(session: session),
                onDone: viewModel.resetScan
            )
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissError()
                }
            }
        )
    }
}

#Preview {
    ContentView()
}
