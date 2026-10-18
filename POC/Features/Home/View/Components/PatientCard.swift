//
//  PatientCard.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//


import SwiftUI

struct PatientCard: View {
    let patient: Patient

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 36))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text(patient.name)
                    .font(.headline)

                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var summary: String {
        let age = patient.age.map { "\($0) years old" } ?? "Age not set"
        let sex = patient.sex?.rawValue ?? "Sex not set"
        return "\(age) · \(sex)"
    }
}
