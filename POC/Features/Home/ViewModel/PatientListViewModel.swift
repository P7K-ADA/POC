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
    @Published private(set) var patients: [PatientEntity] = []
    @Published var searchText = ""
    @Published var errorMessage: String?

    private let store: PatientStore
    private var cancellables = Set<AnyCancellable>()

    init(store: PatientStore) {
        self.store = store
        patients = store.patients

        store.$patients
            .receive(on: RunLoop.main)
            .sink { [weak self] patients in
                self?.patients = patients
            }
            .store(in: &cancellables)
    }

    var filteredPatients: [PatientEntity] {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            return patients
        }

        return patients.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    func deletePatients(at offsets: IndexSet) {
        for index in offsets {
            guard filteredPatients.indices.contains(index) else {
                continue
            }

            do {
                try store.deletePatient(filteredPatients[index])
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
