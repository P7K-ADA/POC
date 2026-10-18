//
//  AddPatientView.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//


import SwiftUI

struct AddPatientView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddPatientViewModel

    init(store: PatientStore) {
        _viewModel = StateObject(
            wrappedValue: AddPatientViewModel(store: store)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Patient Information") {
                    TextField("Name", text: $viewModel.name)
                        .textInputAutocapitalization(.words)

                    TextField("Age", text: $viewModel.ageText)
                        .keyboardType(.numberPad)

                    Picker("Sex", selection: $viewModel.selectedSex) {
                        Text("Not specified")
                            .tag(nil as PatientSex?)

                        ForEach(PatientSex.allCases) { sex in
                            Text(sex.rawValue)
                                .tag(sex as PatientSex?)
                        }
                    }
                }
            }
            .navigationTitle("Add Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.savePatient()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: viewModel.didSave) { _, didSave in
                if didSave {
                    dismiss()
                }
            }
            .alert(
                "Check Patient Information",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "Please check the fields.")
            }
        }
        .preferredColorScheme(.light)
    }
}
