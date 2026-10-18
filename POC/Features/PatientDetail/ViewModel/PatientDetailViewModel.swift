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
    let patient: Patient

    @Published private(set) var sessions: [ScreeningSession] = []
    @Published var errorMessage: String?

    private let sessionStore: ScreeningSessionStore

    init(
        patient: Patient,
        sessionStore: ScreeningSessionStore
    ) {
        self.patient = patient
        self.sessionStore = sessionStore
        self.sessions = sessionStore.sessions(for: patient.id)
    }

    func addSession(_ session: ScreeningSession) {
        do {
            try sessionStore.addSession(session)
            sessions = sessionStore.sessions(for: patient.id)
        } catch {
            errorMessage = "Unable to save session: \(error.localizedDescription)"
        }
    }
}
