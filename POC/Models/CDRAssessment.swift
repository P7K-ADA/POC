//
//  CDRAssesments.swift
//  POC
//
//  Created by Harley Ganisson on 20/10/26.
//

import SwiftUI

/// Cut-offs between screening categories.
/// PLACEHOLDER VALUES: confirm with an ophthalmologist before release.
struct CDRThresholds: Equatable {
    var suspectFrom: Double = 0.5
    var highRiskFrom: Double = 0.7

    static let standard = CDRThresholds()
}

enum CDRStatus: Int, Comparable {
    case unavailable = 0
    case normal
    case suspect
    case highRisk

    init(cdr: Double?, thresholds: CDRThresholds = .standard) {
        guard let cdr else {
            self = .unavailable
            return
        }
        if cdr >= thresholds.highRiskFrom {
            self = .highRisk
        } else if cdr >= thresholds.suspectFrom {
            self = .suspect
        } else {
            self = .normal
        }
    }

    static func < (lhs: CDRStatus, rhs: CDRStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .unavailable: return "Not measured"
        case .normal: return "Normal"
        case .suspect: return "Glaucoma Suspect"
        case .highRisk: return "High Risk Glaucoma"
        }
    }

    var tint: Color {
        switch self {
        case .unavailable: return Color(white: 0.45)
        case .normal: return Color(red: 0.13, green: 0.58, blue: 0.36)
        case .suspect: return Color(red: 0.80, green: 0.47, blue: 0.05)
        case .highRisk: return Color(red: 0.84, green: 0.20, blue: 0.20)
        }
    }

    var nextStepTitle: String {
        switch self {
        case .unavailable: return "Repeat the scan"
        case .normal: return "Continue routine eye checks"
        case .suspect: return "Arrange a comprehensive eye exam"
        case .highRisk: return "Prompt ophthalmology review"
        }
    }

    var nextStepBody: String {
        switch self {
        case .unavailable:
            return "A cup-to-disc ratio could not be measured. Retake the photo and try again."
        case .normal:
            return "No enlarged cup-to-disc ratio was found. A normal screening does not rule out glaucoma, so keep up regular eye exams."
        case .suspect:
            return "An ophthalmologist can check eye pressure, the optic nerve, and visual fields. Suspect does not mean confirmed glaucoma."
        case .highRisk:
            return "Contact an ophthalmologist promptly to check eye pressure, visual fields, and the optic nerve. Seek urgent care for sudden eye pain or vision loss."
        }
    }
}
