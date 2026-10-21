//
//  AddPatientViewModel.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//

import Foundation
import Combine

@MainActor
final class AddPatientViewModel: ObservableObject {
    @Published var name = ""

    @Published var dateOfBirth = Calendar.current.date(
        from: DateComponents(
            year: 2000,
            month: 1,
            day: 1
        )
    )!

    @Published var selectedSex: PatientSex?
    @Published var errorMessage: String?
    @Published private(set) var didSave = false

    private let store: PatientStore

    init(store: PatientStore) {
        self.store = store
    }

    func savePatient() {
        let cleanedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanedName.isEmpty else {
            errorMessage = "Please enter the patient's full name."
            return
        }

        guard Calendar.current.startOfDay(for: dateOfBirth)
                <= Calendar.current.startOfDay(for: .now) else {
            errorMessage = "Date of birth cannot be in the future."
            return
        }

        guard let selectedSex else {
            errorMessage = "Please select the patient's sex."
            return
        }

        do {
            try store.addPatient(
                name: cleanedName,
                dateOfBirth: dateOfBirth,
                sex: selectedSex
            )

            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
