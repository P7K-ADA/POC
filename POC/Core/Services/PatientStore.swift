//
//  PatientStore.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class PatientStore: ObservableObject {
    @Published private(set) var patients: [PatientEntity] = []

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchPatients()
    }

    func fetchPatients() {
        let descriptor = FetchDescriptor<PatientEntity>(
            sortBy: [
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        )

        do {
            patients = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch patients: \(error)")
            patients = []
        }
    }

    func addPatient(
        name: String,
        dateOfBirth: Date,
        sex: PatientSex
    ) throws {
        let cleanedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanedName.isEmpty else {
            throw PatientStoreError.nameIsRequired
        }

        guard Calendar.current.startOfDay(for: dateOfBirth)
                <= Calendar.current.startOfDay(for: .now) else {
            throw PatientStoreError.invalidDateOfBirth
        }

        let patient = PatientEntity(
            name: cleanedName,
            dateOfBirth: dateOfBirth,
            sex: sex.rawValue
        )

        modelContext.insert(patient)

        do {
            try modelContext.save()
            fetchPatients()
        } catch {
            modelContext.delete(patient)
            throw error
        }
    }

    func deletePatient(_ patient: PatientEntity) throws {
        modelContext.delete(patient)

        do {
            try modelContext.save()
            fetchPatients()
        } catch {
            modelContext.rollback()
            fetchPatients()
            throw error
        }
    }
}

enum PatientStoreError: LocalizedError {
    case nameIsRequired
    case invalidDateOfBirth

    var errorDescription: String? {
        switch self {
        case .nameIsRequired:
            return "Please enter the patient's full name."
        case .invalidDateOfBirth:
            return "Date of birth cannot be in the future."
        }
    }
}
