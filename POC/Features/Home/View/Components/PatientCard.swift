//
//  PatientCard.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//

import SwiftUI

struct PatientCard: View {
    let patient: PatientEntity

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
        "\(patient.age) years old · \(patient.sex)"
    }
}
