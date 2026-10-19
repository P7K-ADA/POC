//
//  ReportPalette.swift
//  POC
//
//  Created by Harley Ganisson on 20/10/26.
//


import SwiftUI

enum ReportPalette {
    static let page = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let accent = Color(red: 0.12, green: 0.40, blue: 0.96)
}

extension View {
    func reportCard() -> some View {
        self
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct StatusPill: View {
    let status: CDRStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(status.tint).frame(width: 5, height: 5)
            Text(status.label)
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(status.tint)
        .background(status.tint.opacity(0.14))
        .clipShape(Capsule())
    }
}

struct ReportHeaderView: View {
    let report: ReportData

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(report.patientLine)
                .font(.footnote.weight(.medium))
            Text(report.capturedLine)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct EyeSummaryCard: View {
    let eye: EyeReport
    var showsDetailsLink = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eye.side.rawValue)
                .font(.subheadline.weight(.semibold))

            EyeSchematicView(side: eye.side, cdr: eye.cdr, showsCaption: false)

            HStack(alignment: .firstTextBaseline) {
                Text("CDR")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(eye.cdrText)
                    .font(.title3.monospacedDigit().weight(.semibold))
            }

            StatusPill(status: eye.status)

            if showsDetailsLink {
                HStack(spacing: 2) {
                    Text("View details")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.caption)
                .foregroundStyle(ReportPalette.accent)
            }
        }
        .reportCard()
    }
}

struct SummaryOfFindingsCard: View {
    let report: ReportData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Summary of Findings")
                .font(.subheadline.weight(.semibold))

            ForEach([report.left, report.right]) { eye in
                HStack {
                    Text(eye.side.rawValue)
                        .font(.footnote)
                    Spacer()
                    Text("CDR \(eye.cdrText)")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                    StatusPill(status: eye.status)
                }
            }

            Divider()

            Text(report.summarySentence)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .reportCard()
    }
}

struct RecommendationCard: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RECOMMENDED NEXT STEP")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .reportCard()
    }
}

/// Body shared by the Eye Details screen and the per-eye exported JPG.
struct EyeDetailContent: View {
    let eye: EyeReport

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            EyeSchematicView(side: eye.side, cdr: eye.cdr, aspectRatio: 2.0)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vertical CDR")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(eye.cdrText)
                        .font(.system(size: 34, weight: .semibold).monospacedDigit())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("Screening assessment")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    StatusPill(status: eye.status)
                }
            }
            .reportCard()

            RecommendationCard(
                title: eye.status.nextStepTitle,
                message: eye.status.nextStepBody
            )

            AIDisclaimerView()
        }
    }
}