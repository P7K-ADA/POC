//
//  ReportOverviewView.swift
//  POC
//
//  Created by Harley Ganisson on 20/10/26.
//


import SwiftUI

struct ReportOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ReportViewModel
    private let onDone: () -> Void

    init(
        report: ReportData,
        onDone: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: ReportViewModel(report: report))
        self.onDone = onDone
    }

    init(
        patient: PatientEntity,
        session: ScreeningSession,
        onDone: @escaping () -> Void = {}
    ) {
        self.init(
            report: ReportData.make(
                patient: patient,
                session: session
            ),
            onDone: onDone
        )
    }

    init(
        patient: PatientEntity,
        session: ScreeningSessionEntity,
        onDone: @escaping () -> Void = {}
    ) {
        self.init(
            report: ReportData.make(
                patient: patient,
                session: session
            ),
            onDone: onDone
        )
    }

    private var report: ReportData { viewModel.report }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Report Overview")
                    .font(.title.bold())

                ReportHeaderView(report: report)

                HStack {
                    Text("STRUCTURE SCANS")
                        .font(.system(size: 10, weight: .semibold))
                    Spacer()
                    Text("Schematic · Vertical CDR")
                        .font(.system(size: 10))
                }
                .foregroundStyle(.secondary)

                HStack(alignment: .top, spacing: 12) {
                    eyeLink(report.left)
                    eyeLink(report.right)
                }

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
        dismiss()

        Task { @MainActor in
            await Task.yield()
            onDone()
        }
    }

    private func eyeLink(_ eye: EyeReport) -> some View {
        NavigationLink {
            EyeDetailView(report: report, initialSide: eye.side)
        } label: {
            EyeSummaryCard(eye: eye)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    NavigationStack { ReportOverviewView(report: .sample) }
}
#endif
