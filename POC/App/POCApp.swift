//
//  POCApp.swift
//  POC
//
//  Created by Carolyn Santana on 12/10/26.
//

import SwiftUI

import SwiftData
@main
struct POCApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            PatientEntity.self,
            ScreeningSessionEntity.self,
            EyeExaminationEntity.self,
            AnalysisRunEntity.self,
            ReportEntity.self
        ])
    }
}
