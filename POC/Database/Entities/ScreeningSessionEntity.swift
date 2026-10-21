//
//  ScreeningSessionEntity.swift
//  POC
//
//  Created by Alessandro Moreno Lawadinata on 21/10/26.
//

import Foundation
import SwiftData

@Model
final class ScreeningSessionEntity {
    @Attribute(.unique) var id: UUID
    var examDate: Date
    var status: String
    var createdAt: Date
    
    var patient: PatientEntity?
    
    @Relationship(deleteRule: .cascade, inverse: \EyeExaminationEntity.session)
    var examinations: [EyeExaminationEntity] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ReportEntity.session)
        var reports: [ReportEntity] = []
    
    init(
            id: UUID = UUID(),
            examDate: Date = .now,
            status: String = "Completed",
            createdAt: Date = .now,
            patient: PatientEntity? = nil
        ) {
            self.id = id
            self.examDate = examDate
            self.status = status
            self.createdAt = createdAt
            self.patient = patient
        }
}
