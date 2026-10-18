//
//  PatientStore.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//


import Foundation
import Combine

@MainActor
final class PatientStore: ObservableObject {
    @Published private(set) var patients: [Patient] = []

    private let fileName = "patients.json"

    init() {
        loadPatients()
    }

    func addPatient(name: String, age: Int?, sex: PatientSex?) throws {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty else {
            throw PatientStoreError.nameIsRequired
        }

        patients.insert(
            Patient(name: cleanedName, age: age, sex: sex),
            at: 0
        )
        try savePatients()
    }

    func deletePatient(_ patient: Patient) throws {
        let oldPatients = patients
        patients.removeAll { $0.id == patient.id }

        do {
            try savePatients()
        } catch {
            patients = oldPatients
            throw error
        }
    }

    private var storageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    private func loadPatients() {
        guard let data = try? Data(contentsOf: storageURL) else {
            patients = []
            return
        }

        do {
            patients = try JSONDecoder().decode([Patient].self, from: data)
        } catch {
            patients = []
        }
    }

    private func savePatients() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(patients)
        try data.write(to: storageURL, options: [.atomic])
    }
}

enum PatientStoreError: LocalizedError {
    case nameIsRequired

    var errorDescription: String? {
        "Please enter the patient's name."
    }
}
