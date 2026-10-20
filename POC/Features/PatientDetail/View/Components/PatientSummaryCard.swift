//
//  PatientSummaryCard.swift
//  POC
//
//  Created by Carolyn Santana on 20/10/26.
//



import SwiftUI

struct PatientSummaryCard: View {
    let patient: Patient

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(patient.name)
                .font(.headline)

            Divider()

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Age")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        patient.age.map { "\($0) years" }
                            ?? "Not specified"
                    )
                    .font(.subheadline.weight(.semibold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Sex")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(patient.sex?.rawValue ?? "Not specified")
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}
