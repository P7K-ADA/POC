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
        VStack(alignment: .leading, spacing: 4) {
            Text(patient.name)
                .foregroundStyle(.primary)

            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var summary: String {
        let age = patient.age.map { "\($0) years old" } ?? "Age not set"
        let sex = patient.sex?.rawValue ?? "Sex not set"
        return "\(age) · \(sex)"
    }
}

#Preview {
    PatientCard(
        patient: Patient(name: "Andi Budiman", age: 35, sex: .male)
    )
    .padding()
}
