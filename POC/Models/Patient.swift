//
//  Patient.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//


import Foundation
import UIKit

struct Patient: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var age: Int?
    var sex: PatientSex?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        age: Int? = nil,
        sex: PatientSex? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.sex = sex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum PatientSex: String, Codable, CaseIterable, Identifiable {
    case female = "Female"
    case male = "Male"
    case other = "Other"
    case preferNotToSay = "Prefer not to say"

    var id: String { rawValue }
}

enum ScreeningStatus: String, Codable {
    case completed = "Completed"
}

enum EyeSide: String, Codable {
    case left = "Left eye"
    case right = "Right eye"
}

struct EyeExaminationRecord: Identifiable {
    let id: UUID
    let sessionID: UUID
    let eyeSide: EyeSide
    let image: UIImage?
    let segmentationResult: SegmentationResult?
    let isDummy: Bool

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        eyeSide: EyeSide,
        image: UIImage?,
        segmentationResult: SegmentationResult?,
        isDummy: Bool = false
    ) {
        self.id = id
        self.sessionID = sessionID
        self.eyeSide = eyeSide
        self.image = image
        self.segmentationResult = segmentationResult
        self.isDummy = isDummy
    }

    var verticalCDR: Double? {
        segmentationResult?.verticalCDR
    }
}

struct ScreeningSession: Identifiable {
    let id: UUID
    let patientID: UUID
    let examDate: Date
    let createdAt: Date
    let status: ScreeningStatus
    let leftEye: EyeExaminationRecord
    let rightEye: EyeExaminationRecord

    init(
        id: UUID = UUID(),
        patientID: UUID,
        examDate: Date = .now,
        createdAt: Date = .now,
        status: ScreeningStatus = .completed,
        leftEye: EyeExaminationRecord,
        rightEye: EyeExaminationRecord
    ) {
        self.id = id
        self.patientID = patientID
        self.examDate = examDate
        self.createdAt = createdAt
        self.status = status
        self.leftEye = leftEye
        self.rightEye = rightEye
    }
}
