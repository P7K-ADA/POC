//
//  PatientInformationSection.swift
//  POC
//
//  Created by Carolyn Santana on 20/10/26.
//

import SwiftUI

struct PatientInformationSection: View {
    @Binding var name: String
    @Binding var age: String
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
                Text("Age")
                    .foregroundStyle(.primary)

                Spacer()

                TextField("Enter age", text: $age)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            }

            HStack {
                Text("Sex")
                    .foregroundStyle(.primary)

                Spacer()

                Picker("Sex", selection: $selectedSex) {
                    Text("Not specified")
                        .tag(nil as PatientSex?)

                    ForEach(PatientSex.allCases) { sex in
                        Text(sex.rawValue)
                            .tag(sex as PatientSex?)
                    }
                }
                .labelsHidden()
            }
        } header: {
            Text("Patient Information")
        }
    }
}

#Preview {
    Form {
        PatientInformationSection(
            name: .constant("Andi Budiman"),
            age: .constant("35"),
            selectedSex: .constant(.male)
        )
    }
    .formStyle(.grouped)
}
