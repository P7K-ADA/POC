//
//  PatientSex.swift
//  POC
//
//  Created by Carolyn Santana on 21/10/26.
//

import Foundation

enum PatientSex: String, Codable, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"

    var id: String {
        rawValue
    }
}
