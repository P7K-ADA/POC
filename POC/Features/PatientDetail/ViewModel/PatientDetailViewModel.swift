//
//  PatientDetailViewModel.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//

import Foundation
import Combine

@MainActor
final class PatientDetailViewModel: ObservableObject {
    let patient: PatientEntity

    @Published private(set) var sessions: [ScreeningSessionEntity] = []
    @Published var errorMessage: String?

    private let sessionStore: ScreeningSessionStore

    init(
        patient: PatientEntity,
        sessionStore: ScreeningSessionStore
    ) {
        self.patient = patient
        self.sessionStore = sessionStore
        refreshSessions()
    }

    func refreshSessions() {
        do {
            sessions = try sessionStore.sessions(for: patient.id)
        } catch {
            sessions = []
            errorMessage = "Unable to load sessions: \(error.localizedDescription)"
        }
    }

    func addSession(_ session: ScreeningSession) {
        do {
            try sessionStore.addSession(session)
            refreshSessions()
        } catch {
            errorMessage = "Unable to save session: \(error.localizedDescription)"
        }
    }
}
