//
//  AnalysisRunEntity.swift
//  POC
//
//  Created by Alessandro Moreno Lawadinata on 21/10/26.
//

import Foundation
import SwiftData

@Model
final class AnalysisRunEntity {
    @Attribute(.unique) var id: UUID
    var modelVersion: String
    var status: String
    var startedAt: Date
    var completedAt: Date?
    var errorCode: String?
    var errorMessage: String?
    var verticalCDR: Float?
    var cdrCategory: String?
    var segmentationMaskPath: String?
    var segmentedImagePath: String?
    
    var examination: EyeExaminationEntity?
    
    init(
        id: UUID = UUID(),
        modelVersion: String = "GlaucomaSegmentation-v1",
        status: String = "Completed",
        startedAt: Date = .now,
        completedAt: Date? = .now,
        errorCode: String? = nil,
        errorMessage: String? = nil,
        verticalCDR: Float? = nil,
        cdrCategory: String? = nil,
        segmentationMaskPath: String? = nil,
        segmentedImagePath: String? = nil,
        examination: EyeExaminationEntity? = nil
    )
    {
        self.id = id
        self.modelVersion = modelVersion
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.errorCode = errorCode
        self.errorMessage = errorMessage
        self.verticalCDR = verticalCDR
        self.cdrCategory = cdrCategory
        self.segmentationMaskPath = segmentationMaskPath
        self.segmentedImagePath = segmentedImagePath
        self.examination = examination
    }
}
