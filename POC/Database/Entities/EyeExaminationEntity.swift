//
//  EyeExaminationEntity.swift
//  POC
//
//  Created by Alessandro Moreno Lawadinata on 21/10/26.
//

import Foundation
import SwiftData

@Model
final class EyeExaminationEntity {
    
    @Attribute(.unique) var id: UUID
    var eyeSide: String
    var originalImagePath: String
    var imageQualityStatus: String
    var createdAt: Date
    
    var session: ScreeningSessionEntity?
    
    @Relationship(deleteRule: .cascade, inverse: \AnalysisRunEntity.examination)
    var analysisRun: AnalysisRunEntity?
    
    var report: ReportEntity?
    
    init(
        id: UUID = UUID(),
        eyeSide: String,
        originalImagePath: String,
        imageQualityStatus: String = "Good",
        createdAt: Date = .now,
        session: ScreeningSessionEntity? = nil
    )
    {
        self.id = id
        self.eyeSide = eyeSide
        self.originalImagePath = originalImagePath
        self.imageQualityStatus = imageQualityStatus
        self.createdAt = createdAt
        self.session = session
    }
}
