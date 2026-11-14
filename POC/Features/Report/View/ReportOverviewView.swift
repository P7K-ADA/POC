//
//  ReportOverviewView.swift
//  POC
//
//  Created by Harley Ganisson on 20/10/26.
//

import SwiftUI

struct ReportOverviewView: View {
    @StateObject private var viewModel: ReportViewModel
    private let onDone: () -> Void

    init(
        report: ReportData,
        onDone: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: ReportViewModel(report: report))
        self.onDone = onDone
    }

    private var report: ReportData { viewModel.report }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                ReportEyeScansSection(report: report)
                
                PreprocessingDetailsSection(report: report)

                RecommendationCard(
                    title: report.recommendation.title,
                    message: report.recommendation.message
                )

                AIDisclaimerView()
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, Layout.topPadding)
            .padding(.bottom, Layout.reviewBottomPadding)
        }
        .background(AppColors.backgroundSecondary)
        .navigationTitle("Overview")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done", action: handleDone)
                .accessibilityHint("Closes the report.")
            }
        }
        .safeAreaInset(edge: .bottom) {
            AppButton(
                title: viewModel.isExporting ? "Menyimpan..." : "Ekspor Foto",
                tint: AppColors.accentBlue,
                action: viewModel.exportReport
            )
            .disabled(viewModel.isExporting)
            .accessibilityHint("Export report as images.")
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.reviewBottomPadding)
            .background(AppColors.backgroundSecondary)
        }
        .fullScreenCover(isPresented: $viewModel.showingExportSuccess) {
            ReportExportSuccessView(
                onBack: { viewModel.showingExportSuccess = false },
                onStartNew: {
                    viewModel.showingExportSuccess = false
                    finishReport()
                }
            )
        }
        .alert("Ekspor gagal", isPresented: Binding(
            get: { viewModel.exportError != nil },
            set: { if !$0 { viewModel.exportError = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.exportError = nil }
        } message: {
            Text(viewModel.exportError ?? "Coba lagi.")
        }
        .alert("Hasil Pemeriksaan Akan Dihapus", isPresented: $viewModel.showingUnsavedExportAlert) {
            Button("Ekspor Foto") {
                viewModel.exportReport()
            }
            Button("Hapus", role: .destructive) {
                finishReport()
            }
            Button("Batal", role: .cancel) { }
        } message: {
            Text("Foto belum diekspor. Apakah Anda ingin mengekspor foto terlebih dahulu?")
        }
    }

    private func finishReport() {
        onDone()
    }

    private func handleDone() {
        if viewModel.hasExported {
            finishReport()
        } else {
            viewModel.showingUnsavedExportAlert = true
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack { ReportOverviewView(report: .sample) }
}
#endif
