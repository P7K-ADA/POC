//
//  PatientDetailView.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//

import SwiftUI

struct PatientDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let onReturnHome: () -> Void
    @StateObject private var viewModel: PatientDetailViewModel
    @State private var showingScan = false
    @State private var showingFAQ = false

    init(
        patient: PatientEntity,
        sessionStore: ScreeningSessionStore,
        onReturnHome: @escaping () -> Void = {}
    ) {
        self.onReturnHome = onReturnHome
        _viewModel = StateObject(
            wrappedValue: PatientDetailViewModel(
                patient: patient,
                sessionStore: sessionStore
            )
        )
    }

    private func returnToHome() {
        dismiss()
        onReturnHome()
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                PatientDetailHeader(
                    onBack: { dismiss() },
                    onFAQ: { showingFAQ = true }
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        PatientSummaryCard(
                            patient: viewModel.patient
                        )

                        Text(
                            "Previous Scans · \(viewModel.sessions.count)"
                        )
                        .font(.subheadline)
                        .padding(.horizontal, 8)

                        if viewModel.sessions.isEmpty {
                            PatientDetailEmptyState()
                                .frame(
                                    maxWidth: .infinity,
                                    minHeight: 300
                                )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.sessions) { session in
                                    ScreeningSessionCard(
                                        patient: viewModel.patient,
                                        session: session,
                                        onDone: returnToHome
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            StartScanningButton {
                showingScan = true
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showingScan) {
            ScanView(
                patient: viewModel.patient,
                onSaveSession: { session in
                    viewModel.addSession(session)
                },
                onDone: {
                    showingScan = false
                    returnToHome()
                }
            )
        }
        .alert("FAQ", isPresented: $showingFAQ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Patient detail help will be available here.")
        }
        .preferredColorScheme(.light)
    }
}
