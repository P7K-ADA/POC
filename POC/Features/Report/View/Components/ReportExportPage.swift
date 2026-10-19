//
//  ReportExportPage.swift
//  POC
//
//  Created by Harley Ganisson on 20/10/26.
//


import SwiftUI

/// Fixed-width pages that ImageRenderer turns into JPGs.
/// Every page carries patient name, capture date and the AI disclaimer.
struct ReportExportPage<Content: View>: View {
    let title: String
    let report: ReportData
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title.bold())
            ReportHeaderView(report: report)
            content
        }
        .padding(20)
        .frame(width: 390, alignment: .topLeading)
        .background(ReportPalette.page)
        .environment(\.colorScheme, .light)
    }
}

struct OverviewExportPage: View {
    let report: ReportData

    var body: some View {
        ReportExportPage(title: "Report Overview", report: report) {
            HStack(alignment: .top, spacing: 12) {
                EyeSummaryCard(eye: report.left, showsDetailsLink: false)
                EyeSummaryCard(eye: report.right, showsDetailsLink: false)
            }
            SummaryOfFindingsCard(report: report)
            RecommendationCard(
                title: report.recommendation.title,
                message: report.recommendation.message
            )
            AIDisclaimerView()
        }
    }
}

struct EyeExportPage: View {
    let report: ReportData
    let side: EyeSide

    var body: some View {
        ReportExportPage(title: side.rawValue, report: report) {
            EyeDetailContent(eye: report.eye(side))
        }
    }
}