//
//  ReportEyeScansSection.swift
//  POC
//

import SwiftUI

struct ReportEyeScansSection: View {
    let report: ReportData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("STRUCTURE SCANS")
                    .font(.system(size: 10, weight: .semibold))

                Spacer()

                Text("Schematic · Vertical CDR")
                    .font(.system(size: 10))
            }
            .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 12) {
                ReportEyeNavigationLink(eye: report.left, report: report)
                ReportEyeNavigationLink(eye: report.right, report: report)
            }
        }
    }
}

private struct ReportEyeNavigationLink: View {
    let eye: EyeReport
    let report: ReportData

    var body: some View {
        NavigationLink {
            EyeDetailView(report: report, initialSide: eye.side)
        } label: {
            EyeSummaryCard(eye: eye)
        }
        .buttonStyle(.plain)
    }
}
