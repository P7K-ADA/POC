//
//  ScreeningSessionStore.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//

import Foundation
import SwiftData
import UIKit

@MainActor
final class ScreeningSessionStore {
    private let modelContext: ModelContext
    private let fileStorage = LocalFileStorage.shared

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func sessions(for patientID: UUID) throws -> [ScreeningSessionEntity] {
        let descriptor = FetchDescriptor<ScreeningSessionEntity>(
            sortBy: [SortDescriptor(\.examDate, order: .reverse)]
        )

        return try modelContext.fetch(descriptor).filter {
            $0.patient?.id == patientID
        }
    }

    @discardableResult
    func addSession(
        _ session: ScreeningSession
    ) throws -> ScreeningSessionEntity {
        let descriptor = FetchDescriptor<PatientEntity>()

        guard let patient = try modelContext.fetch(descriptor)
            .first(where: { $0.id == session.patientID }) else {
            throw ScreeningSessionStoreError.patientNotFound
        }

        let entity = ScreeningSessionEntity(
            id: session.id,
            examDate: session.examDate,
            status: session.status.rawValue,
            createdAt: session.createdAt,
            patient: patient
        )

        modelContext.insert(entity)

        do {
            try addExamination(session.leftEye, to: entity)
            try addExamination(session.rightEye, to: entity)

            try modelContext.save()
            return entity
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func addExamination(
        _ record: EyeExaminationRecord,
        to session: ScreeningSessionEntity
    ) throws {
        var imagePath = ""

        if let image = record.image {
            guard let savedPath = fileStorage.saveImage(
                image,
                fileName: record.id.uuidString
            ) else {
                throw ScreeningSessionStoreError.fileSaveFailed
            }

            imagePath = savedPath
        }

        let examination = EyeExaminationEntity(
            id: record.id,
            eyeSide: record.eyeSide.rawValue,
            originalImagePath: imagePath,
            imageQualityStatus: record.isDummy ? "Unavailable" : "Good",
            createdAt: .now,
            session: session
        )

        modelContext.insert(examination)

        guard let result = record.segmentationResult else {
            return
        }

        guard let maskPath = fileStorage.saveMask(
            data: result.mask,
            fileName: "\(record.id.uuidString)-mask"
        ) else {
            throw ScreeningSessionStoreError.fileSaveFailed
        }

        let analysis = AnalysisRunEntity(
            status: "Completed",
            startedAt: .now,
            completedAt: .now,
            verticalCDR: result.verticalCDR.map { Float($0) },
            cdrCategory: CDRStatus(cdr: result.verticalCDR).label,
            segmentationMaskPath: maskPath,
            examination: examination
        )

        modelContext.insert(analysis)
    }
}

enum ScreeningSessionStoreError: LocalizedError {
    case patientNotFound
    case fileSaveFailed

    var errorDescription: String? {
        switch self {
        case .patientNotFound:
            return "The patient could not be found."
        case .fileSaveFailed:
            return "The examination image or segmentation mask could not be saved."
        }
    }
}
