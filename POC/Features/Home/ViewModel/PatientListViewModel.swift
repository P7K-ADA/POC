//
//  PatientListViewModel.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//


import Foundation
import Combine

@MainActor
final class PatientListViewModel: ObservableObject {
    @Published private(set) var patients: [Patient] = []
    @Published var errorMessage: String?

    private let store: PatientStore

    init(store: PatientStore) {
        self.store = store
        self.patients = store.patients
        // Keep the view model in sync with the store.
        store.$patients
            .receive(on: RunLoop.main)
            .assign(to: &$patients)
    }

    func deletePatient(at offsets: IndexSet) {
        for index in offsets {
            guard patients.indices.contains(index) else { continue }

            do {
                try store.deletePatient(patients[index])
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
