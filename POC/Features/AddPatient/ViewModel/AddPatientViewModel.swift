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
    @Published var ageText = ""
    @Published var selectedSex: PatientSex?
    @Published var errorMessage: String?
    @Published private(set) var didSave = false

    private let store: PatientStore

    init(store: PatientStore) {
        self.store = store
    }

    func savePatient() {
        let cleanedAge = ageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let age: Int?

        if cleanedAge.isEmpty {
            age = nil
        } else if let parsedAge = Int(cleanedAge), (0...130).contains(parsedAge) {
            age = parsedAge
        } else {
            errorMessage = "Enter a valid age between 0 and 130, or leave it blank."
            return
        }

        do {
            try store.addPatient(
                name: name,
                age: age,
                sex: selectedSex
            )
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
