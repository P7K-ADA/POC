//
//  ReportData.swift
//  POC
//
//  Created by Harley Ganisson on 20/10/26.
//

import Foundation
import UIKit

struct EyeReport: Identifiable {
    let side: EyeSide
    let cdr: Double?
    let status: CDRStatus
    let image: UIImage?
    let segmentationMask: [UInt8]?
    let maskWidth: Int
    let maskHeight: Int

    let debugStages: [String: UIImage]
    let confidence: Double?

    init(
        side: EyeSide,
        cdr: Double?,
        thresholds: CDRThresholds = .standard,
        image: UIImage? = nil,
        segmentationMask: [UInt8]? = nil,
        maskWidth: Int = 512,
        maskHeight: Int = 512,
        debugStages: [String: UIImage] = [:],
        confidence: Double? = nil
    ) {
        self.side = side
        self.cdr = cdr
        self.status = CDRStatus(cdr: cdr, thresholds: thresholds)
        self.image = image
        self.segmentationMask = segmentationMask
        self.maskWidth = maskWidth
        self.maskHeight = maskHeight
        self.debugStages = debugStages
        self.confidence = confidence
    }

    var id: EyeSide { side }
    var cdrText: String {
        cdr.map { String(format: "%.2f", $0) } ?? "—"
    }
}

struct ReportRecommendation: Equatable {
    let title: String
    let message: String
}

/// Plain value type holding everything the report screens and JPG exports need.
struct ReportData {
    let capturedLine: String
    let left: EyeReport
    let right: EyeReport

    var overall: CDRStatus { max(left.status, right.status) }

    func eye(_ side: EyeSide) -> EyeReport {
        side == .left ? left : right
    }

    static func make(
        session: ScreeningSession,
        thresholds: CDRThresholds = .standard
    ) -> ReportData {
        func report(_ side: EyeSide, _ record: EyeExaminationRecord) -> EyeReport {
            let cdr = record.verticalCDR
            let result = record.segmentationResult
            return EyeReport(
                side: side,
                cdr: cdr,
                thresholds: thresholds,
                image: record.image,
                segmentationMask: result?.mask,
                maskWidth: result?.width ?? 512,
                maskHeight: result?.height ?? 512,
                debugStages: record.debugStages,
                confidence: record.confidence
            )
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMM yyyy, h:mm a"

        return ReportData(
            capturedLine: "Captured \(formatter.string(from: session.examDate))",
            left: report(.left, session.leftEye),
            right: report(.right, session.rightEye)
        )
    }

    // MARK: - Recommended next step (follows the worse eye)

    var recommendation: ReportRecommendation {
        if left.status == .unavailable && right.status == .unavailable {
            return ReportRecommendation(
                title: "vCDR Tidak Terdeteksi",
                message: "Ambil ulang foto kedua mata untuk mendapatkan hasil pemeriksaan."
            )
        }

        if left.status == .unavailable || right.status == .unavailable {
            return ReportRecommendation(
                title: CDRStatus.unavailable.nextStepTitle,
                message: CDRStatus.unavailable.nextStepBody
            )
        }

        if left.status == .normal && right.status == .normal {
            return ReportRecommendation(
                title: "Kedua Mata dalam Batas Normal",
                message: "Lanjutkan pemeriksaan mata secara rutin."
            )
        }

        guard overall == .suspect || overall == .highRisk else {
            return ReportRecommendation(
                title: overall.nextStepTitle,
                message: overall.nextStepBody
            )
        }
        let flagged = [left, right].filter { $0.status == overall }
        let title: String
        let side = flagged.first?.side == .left ? "OS" : "OD"
        title = "Indikasi Rasio vCDR Meningkat (\(side))"
        return ReportRecommendation(
            title: title,
            message: "Jadwalkan pemeriksaan mata lebih lanjut dan konsultasikan hasil kedua mata dengan dokter spesialis."
        )
    }
}

#if DEBUG
extension ReportData {
    static let sample = ReportData(
        capturedLine: "Captured 17 Oct 2026, 9:38 AM",
        left: EyeReport(side: .left, cdr: 0.30),
        right: EyeReport(side: .right, cdr: 0.42)
    )
}
#endif
