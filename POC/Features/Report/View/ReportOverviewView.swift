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
                Text("Report Overview")
                    .font(.title.bold())

                ReportHeaderView(capturedLine: report.capturedLine)

                ReportEyeScansSection(report: report)

                //SummaryOfFindingsCard(report: report)

                RecommendationCard(
                    title: report.recommendation.title,
                    message: report.recommendation.message
                )

                AIDisclaimerView()
            }
            .padding()
        }
        .background(ReportPalette.page)
        .preferredColorScheme(.light)
        .navigationTitle("Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done", action: finishReport)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                viewModel.showingExport = true
            } label: {
                Text("Export JPGs")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(ReportPalette.page)
        }
        .sheet(isPresented: $viewModel.showingExport) {
            ExportJPGsSheet(report: report)
                .presentationDetents([.large])
        }
    }

    private func finishReport() {
        onDone()
    }
}

#if DEBUG
#Preview {
    NavigationStack { ReportOverviewView(report: .sample) }
}
#endif
