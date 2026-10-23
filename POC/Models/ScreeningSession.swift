//
//  ScreeningSession.swift
//  POC
//
//  Created by Carolyn Santana on 21/10/26.
//



import Foundation

struct ScreeningSession: Identifiable {
    let id: UUID
    let examDate: Date
    let createdAt: Date
    let status: ScreeningStatus
    let leftEye: EyeExaminationRecord
    let rightEye: EyeExaminationRecord

    init(
        id: UUID = UUID(),
        examDate: Date = .now,
        createdAt: Date = .now,
        status: ScreeningStatus = .completed,
        leftEye: EyeExaminationRecord,
        rightEye: EyeExaminationRecord
    ) {
        self.id = id
        self.examDate = examDate
        self.createdAt = createdAt
        self.status = status
        self.leftEye = leftEye
        self.rightEye = rightEye
    }
}
