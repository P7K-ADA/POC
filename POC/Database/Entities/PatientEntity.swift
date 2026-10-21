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
    var dateOfBirth: Date
    var sex: String

    var createdAt: Date
    var updatedAt: Date

    var age: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let birthDate = calendar.startOfDay(for: dateOfBirth)

        guard birthDate <= today else {
            return 0
        }

        return calendar.dateComponents(
            [.year],
            from: birthDate,
            to: today
        ).year ?? 0
    }

    @Relationship(
        deleteRule: .cascade,
        inverse: \ScreeningSessionEntity.patient
    )
    var sessions: [ScreeningSessionEntity] = []

    init(
        id: UUID = UUID(),
        name: String,
        dateOfBirth: Date,
        sex: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.sex = sex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
