//
//  ReportData.swift
//  POC
//
//  Created by Harley Ganisson on 20/10/26.
//

import Foundation

struct EyeReport: Identifiable, Equatable {
    let side: EyeSide
    let cdr: Double?
    let status: CDRStatus

    var id: EyeSide { side }
    var cdrText: String { cdr.map { String(format: "%.2f", $0) } ?? "N/A" }
}

struct ReportRecommendation: Equatable {
    let title: String
    let message: String
}

/// Plain value type holding everything the report screens and JPG exports need.
struct ReportData: Equatable {
    let patientLine: String
    let capturedLine: String
    let left: EyeReport
    let right: EyeReport

    var overall: CDRStatus { max(left.status, right.status) }

    func eye(_ side: EyeSide) -> EyeReport {
        side == .left ? left : right
    }

    static func make(
        patient: Patient,
        session: ScreeningSession,
        thresholds: CDRThresholds = .standard
    ) -> ReportData {
        func report(_ side: EyeSide, _ record: EyeExaminationRecord) -> EyeReport {
            let cdr = record.verticalCDR
            return EyeReport(
                side: side,
                cdr: cdr,
                status: CDRStatus(cdr: cdr, thresholds: thresholds)
            )
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMM yyyy, h:mm a"

        var patientLine = patient.name
        if let age = patient.age {
            patientLine += " · \(age) years old"
        }

        return ReportData(
            patientLine: patientLine,
            capturedLine: "Captured \(formatter.string(from: session.examDate))",
            left: report(.left, session.leftEye),
            right: report(.right, session.rightEye)
        )
    }

    // MARK: - Summary of Findings

    var summarySentence: String {
        if overall == .unavailable {
            return "No cup-to-disc ratio could be measured for either eye. Retake the photos and try again."
        }
        if left.status == .unavailable || right.status == .unavailable {
            let missing = left.status == .unavailable ? "left" : "right"
            return "A cup-to-disc ratio could not be measured for the \(missing) eye. Retake that photo for a complete report."
        }
        if left.status == right.status {
            return overall == .normal
                ? "Both eyes are in the normal CDR range on this screening."
                : "Both eyes show an elevated vertical CDR (\(overall.label))."
        }
        let worse = left.status > right.status ? left : right
        let other = left.status > right.status ? right : left
        return "The \(worse.side.rawValue.lowercased()) has the higher CDR (\(worse.cdrText) vs \(other.cdrText)). Prioritize it in the eye-care review."
    }

    // MARK: - Recommended next step (follows the worse eye)

    var recommendation: ReportRecommendation {
        guard overall == .suspect else {
            return ReportRecommendation(
                title: overall.nextStepTitle,
                message: overall.nextStepBody
            )
        }
        let flagged = [left, right].filter { $0.status == overall }
        let title: String
        if flagged.count == 2 {
            title = "Review both eyes"
        } else if flagged.first?.side == .left {
            title = "Review left-eye result"
        } else {
            title = "Review right-eye result"
        }
        return ReportRecommendation(
            title: title,
            message: "Arrange an eye-care review. Compare both eyes with an eye specialist."
        )
    }
}

#if DEBUG
extension ReportData {
    static let sample = ReportData(
        patientLine: "Alex Morgan · 32 years old",
        capturedLine: "Captured 17 Oct 2026, 9:38 AM",
        left: EyeReport(side: .left, cdr: 0.66, status: CDRStatus(cdr: 0.66)),
        right: EyeReport(side: .right, cdr: 0.42, status: CDRStatus(cdr: 0.42))
    )
}
#endif
