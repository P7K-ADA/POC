//
//  PatientInformationSection.swift
//  POC
//
//  Created by Carolyn Santana on 20/10/26.
//

import SwiftUI

struct PatientInformationSection: View {
    @Binding var name: String
    @Binding var dateOfBirth: Date
    @Binding var selectedSex: PatientSex?

    var body: some View {
        Section {
            HStack {
                Text("Full Name")
                    .foregroundStyle(.primary)

                Spacer()

                TextField("Enter full name", text: $name)
                    .multilineTextAlignment(.trailing)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
            }

            HStack {
                Text("Date Of Birth")
                    .foregroundStyle(.primary)

                Spacer()

                DatePicker(
                    "Date Of Birth",
                    selection: $dateOfBirth,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .labelsHidden()
            }

            HStack {
                Text("Sex")
                    .foregroundStyle(.primary)

                Spacer()

                Picker("Sex", selection: $selectedSex) {
                    Text("Male")
                        .tag(PatientSex.male as PatientSex?)

                    Text("Female")
                        .tag(PatientSex.female as PatientSex?)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 220)
            }
        } header: {
            Text("Patient Information")
        }
    }
}

