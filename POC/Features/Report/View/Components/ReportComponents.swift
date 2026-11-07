//
//  ReportPalette.swift
//  POC
//
//  Created by Harley Ganisson on 20/10/26.
//


import SwiftUI
import UIKit

enum ReportPalette {
    static let page = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let accent = Color(red: 0.12, green: 0.40, blue: 0.96)
}

extension View {
    func reportCard(background: Color = .white) -> some View {
        self
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct StatusPill: View {
    let status: CDRStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(status.tint).frame(width: 5, height: 5)
                .accessibilityHidden(true)
            Text(status.label)
                .font(.caption.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(status.tint)
        .background(Color.clear)
        .clipShape(Capsule())
    }
}

struct ReportHeaderView: View {
    let capturedLine: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(capturedLine)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct SegmentationImageView: View {
    let side: EyeSide
    let image: UIImage?
    let segmentationMask: [UInt8]?
    let maskWidth: Int
    let maskHeight: Int
    var aspectRatio: CGFloat = 1.1

    var body: some View {
        Group {
            if let image {
                GeometryReader { geometry in
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width,
                                   height: geometry.size.height)
                            .clipped()

                        if let segmentationMask,
                           let overlay = SegmentationOverlay.makeImage(
                            from: segmentationMask,
                            width: maskWidth,
                            height: maskHeight
                           ) {
                            Image(uiImage: overlay)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width,
                                       height: geometry.size.height)
                                .clipped()
                        }
                    }
                }
                .aspectRatio(aspectRatio, contentMode: .fit)
                .clipped()
                .allowsHitTesting(false)
            } else {
                EyeSchematicView(side: side, cdr: nil,
                                 showsCaption: false, aspectRatio: aspectRatio)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct EyeSummaryCard: View {
    let eye: EyeReport
    var showsDetailsLink = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eye.side.rawValue)
                .font(.headline)

            SegmentationImageView(
                side: eye.side,
                image: eye.image,
                segmentationMask: eye.segmentationMask,
                maskWidth: eye.maskWidth,
                maskHeight: eye.maskHeight
            ).accessibilityHidden(true)

            HStack(alignment: .firstTextBaseline) {
                Text("CDR")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(eye.cdrText)
                    .font(.title3.monospacedDigit().weight(.semibold))
            }

            StatusPill(status: eye.status)
                .accessibilityElement(children: .ignore)

            if showsDetailsLink {
                HStack(spacing: 2) {
                    Text("View details")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.footnote)
                .foregroundStyle(ReportPalette.accent)
            }
        }
        .reportCard(background: eye.status.tint.opacity(0.14))
    }
}

//struct SummaryOfFindingsCard: View {
//    let report: ReportData
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text("Summary of Findings")
//                .font(.subheadline.weight(.semibold))
//
//            ForEach([report.left, report.right]) { eye in
//                HStack {
//                    Text(eye.side.rawValue)
//                        .font(.footnote)
//                    Spacer()
//                    Text("CDR \(eye.cdrText)")
//                        .font(.footnote.monospacedDigit())
//                        .foregroundStyle(.secondary)
//                    StatusPill(status: eye.status)
//                }
//            }
//
//            Divider()
//
//            Text(report.summarySentence)
//                .font(.footnote)
//                .foregroundStyle(.secondary)
//                .fixedSize(horizontal: false, vertical: true)
//        }
//        .reportCard()
//    }
//}

struct RecommendationCard: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RECOMMENDED NEXT STEP")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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

            SegmentationImageView(
                side: eye.side,
                image: eye.image,
                segmentationMask: eye.segmentationMask,
                maskWidth: eye.maskWidth,
                maskHeight: eye.maskHeight,
                aspectRatio: 2.0
                )
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 16) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("Vertical CDR")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(eye.cdrText)
                        .font(.largeTitle.weight(.semibold).monospacedDigit())
                        .fixedSize(horizontal: false, vertical: true)
                    
                    StatusPill(status: eye.status)
                    
                }
            }
        }
            .frame(maxWidth: .infinity, alignment: .leading)
            .reportCard(background: eye.status.tint.opacity(0.14))

            RecommendationCard(
                title: eye.status.nextStepTitle,
                message: eye.status.nextStepBody
            )

            AIDisclaimerView()
    }
}

