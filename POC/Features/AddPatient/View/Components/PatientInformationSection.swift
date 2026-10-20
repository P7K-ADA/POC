
import SwiftUI

struct PatientInformationSection: View {
    @Binding var name: String
    @Binding var age: String
    @Binding var selectedSex: PatientSex?

    var body: some View {
        Section {
            TextField("Enter full name", text: $name)
                .textContentType(.name)
                .textInputAutocapitalization(.words)

            TextField("Enter age", text: $age)
                .keyboardType(.numberPad)

            Picker("Sex", selection: $selectedSex) {
                Text("Not specified")
                    .tag(nil as PatientSex?)

                ForEach(PatientSex.allCases) { sex in
                    Text(sex.rawValue)
                        .tag(sex as PatientSex?)
                }
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
