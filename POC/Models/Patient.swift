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


