//
//  ReportEyeScansSection.swift
//  POC
//

import SwiftUI

struct ReportEyeScansSection: View {
    let report: ReportData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ReportEyeNavigationLink(eye: report.left, report: report)
                    ReportEyeNavigationLink(eye: report.right, report: report)
                }

                VStack(spacing: 12) {
                    ReportEyeNavigationLink(eye: report.left, report: report)
                    ReportEyeNavigationLink(eye: report.right, report: report)
                }
            }
            .foregroundStyle(.secondary)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(eye.side.rawValue)")
        .accessibilityValue("CDR \(eye.cdrText),  \(eye.status.label)")
        .accessibilityHint("Opens details for this eye.")
    }
}
