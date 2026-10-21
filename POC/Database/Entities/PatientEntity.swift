//
//  PatientEntity.swift
//  POC
//
//  Created by Alessandro Moreno Lawadinata on 21/10/26.
//

import Foundation
import SwiftData

@Model
final class PatientEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int?
    var sex: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \ScreeningSessionEntity.patient)
    var sessions: [ScreeningSessionEntity] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        age: Int? = nil,
        sex: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    )
    {
        self.id = id
        self.name = name
        self.age = age
        self.sex = sex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
