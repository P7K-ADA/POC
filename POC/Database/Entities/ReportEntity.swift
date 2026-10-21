//
//  ReportEntity.swift
//  POC
//
//  Created by Alessandro Moreno Lawadinata on 21/10/26.
//

import Foundation
import SwiftData

@Model
final class ReportEntity {
    @Attribute(.unique) var id: UUID
    var format: String
    var filePath: String
    var createdAt: Date
    
    var session: ScreeningSessionEntity?
    var examination: EyeExaminationEntity?
    
    init(
        id: UUID = UUID(),
        format: String = "PDF",
        filePath: String,
        createdAt: Date = .now,
        session: ScreeningSessionEntity? = nil,
        examination: EyeExaminationEntity? = nil
    )
    
    {
        self.id = id
        self.format = format
        self.filePath = filePath
        self.createdAt = createdAt
        self.session = session
        self.examination = examination
    }
}
