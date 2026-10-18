//
//  ScreeningSessionStore.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//



import Foundation
import UIKit

@MainActor
final class ScreeningSessionStore: ObservableObject {
    @Published private(set) var sessions: [ScreeningSession] = []

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var rootURL: URL {
        fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        .appendingPathComponent("GlaucoScan", isDirectory: true)
    }

    private var sessionsURL: URL {
        rootURL.appendingPathComponent(
            "screening_sessions.json"
        )
    }

    private var imagesURL: URL {
        rootURL.appendingPathComponent("images", isDirectory: true)
    }

    private var masksURL: URL {
        rootURL.appendingPathComponent("masks", isDirectory: true)
    }

    private var metadataURL: URL {
        rootURL.appendingPathComponent(
            "session_metadata",
            isDirectory: true
        )
    }

    init() {
        createDirectories()
        loadSessions()
    }

    func sessions(for patientID: UUID) -> [ScreeningSession] {
        sessions
            .filter { $0.patientID == patientID }
            .sorted { $0.examDate > $1.examDate }
    }

    func addSession(_ session: ScreeningSession) throws {
        // Save files first. Do not publish the session if saving fails.
        try saveImage(session.leftEye)
        try saveImage(session.rightEye)
        try saveMask(session.leftEye)
        try saveMask(session.rightEye)

        let previousSessions = sessions
        sessions.insert(session, at: 0)

        do {
            try persistMetadata()
        } catch {
            sessions = previousSessions
            throw error
        }
    }

    private func createDirectories() {
        for url in [
            rootURL,
            imagesURL,
            masksURL,
            metadataURL
        ] {
            try? fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
        }
    }

    private func saveImage(
        _ eye: EyeExaminationRecord
    ) throws {
        guard let image = eye.image,
              let data = image.jpegData(compressionQuality: 0.95)
        else {
            return
        }

        let url = imagesURL.appendingPathComponent(
            "\(eye.id.uuidString).jpg"
        )

        try data.write(to: url, options: .atomic)
    }

    private func saveMask(
        _ eye: EyeExaminationRecord
    ) throws {
        guard let result = eye.segmentationResult else {
            return
        }

        let url = masksURL.appendingPathComponent(
            "\(eye.id.uuidString).bin"
        )

        let data = Data(result.mask)
        try data.write(to: url, options: .atomic)
    }

    private func persistMetadata() throws {
        let records = sessions.map { session in
            PersistedSession(
                id: session.id,
                patientID: session.patientID,
                examDate: session.examDate,
                createdAt: session.createdAt,
                status: session.status,
                leftEye: PersistedEye(
                    id: session.leftEye.id,
                    sessionID: session.id,
                    eyeSide: session.leftEye.eyeSide,
                    isDummy: session.leftEye.isDummy,
                    hasImage: session.leftEye.image != nil,
                    analysis: PersistedAnalysis(
                        result: session.leftEye.segmentationResult
                    )
                ),
                rightEye: PersistedEye(
                    id: session.rightEye.id,
                    sessionID: session.id,
                    eyeSide: session.rightEye.eyeSide,
                    isDummy: session.rightEye.isDummy,
                    hasImage: session.rightEye.image != nil,
                    analysis: PersistedAnalysis(
                        result: session.rightEye.segmentationResult
                    )
                )
            )
        }

        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(records)
        try data.write(to: sessionsURL, options: .atomic)
    }

    private func loadSessions() {
        guard let data = try? Data(contentsOf: sessionsURL),
              let records = try? decoder.decode(
                [PersistedSession].self,
                from: data
              )
        else {
            sessions = []
            return
        }

        sessions = records.compactMap { record in
            guard
                let left = restoreEye(record.leftEye),
                let right = restoreEye(record.rightEye)
            else {
                return nil
            }

            return ScreeningSession(
                id: record.id,
                patientID: record.patientID,
                examDate: record.examDate,
                createdAt: record.createdAt,
                status: record.status,
                leftEye: left,
                rightEye: right
            )
        }
    }

    private func restoreEye(
        _ eye: PersistedEye
    ) -> EyeExaminationRecord? {
        let imageURL = imagesURL.appendingPathComponent(
            "\(eye.id.uuidString).jpg"
        )
        let image = UIImage(contentsOfFile: imageURL.path)

        var result: SegmentationResult?

        if let analysis = eye.analysis,
           let saved = analysis.result {
            let maskURL = masksURL.appendingPathComponent(
                "\(eye.id.uuidString).bin"
            )

            if let maskData = try? Data(contentsOf: maskURL),
               maskData.count == saved.width * saved.height {
                result = SegmentationResult(
                    mask: Array(maskData),
                    width: saved.width,
                    height: saved.height,
                    verticalCDR: saved.verticalCDR,
                    discPixelCount: saved.discPixelCount,
                    cupPixelCount: saved.cupPixelCount
                )
            }
        }

        return EyeExaminationRecord(
            id: eye.id,
            sessionID: eye.sessionID,
            eyeSide: eye.eyeSide,
            image: image,
            segmentationResult: result,
            isDummy: eye.isDummy
        )
    }
}

// MARK: - Persisted Metadata

private struct PersistedSession: Codable {
    let id: UUID
    let patientID: UUID
    let examDate: Date
    let createdAt: Date
    let status: ScreeningStatus
    let leftEye: PersistedEye
    let rightEye: PersistedEye
}

private struct PersistedEye: Codable {
    let id: UUID
    let sessionID: UUID
    let eyeSide: EyeSide
    let isDummy: Bool
    let hasImage: Bool
    let analysis: PersistedAnalysis?
}

private struct PersistedAnalysis: Codable {
    let result: PersistedResult?

    init(result: SegmentationResult?) {
        if let result {
            self.result = PersistedResult(
                width: result.width,
                height: result.height,
                verticalCDR: result.verticalCDR,
                discPixelCount: result.discPixelCount,
                cupPixelCount: result.cupPixelCount
            )
        } else {
            self.result = nil
        }
    }
}

private struct PersistedResult: Codable {
    let width: Int
    let height: Int
    let verticalCDR: Double?
    let discPixelCount: Int
    let cupPixelCount: Int
}
