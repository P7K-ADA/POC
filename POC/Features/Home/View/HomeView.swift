//
//  HomeView.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var store: PatientStore
    @StateObject private var viewModel: PatientListViewModel
    @StateObject private var sessionStore: ScreeningSessionStore

    @State private var showingAddPatient = false

    init() {
        let patientStore = PatientStore()
        let screeningSessionStore = ScreeningSessionStore()

        _store = StateObject(
            wrappedValue: patientStore
        )

        _viewModel = StateObject(
            wrappedValue: PatientListViewModel(
                store: patientStore
            )
        )

        _sessionStore = StateObject(
            wrappedValue: screeningSessionStore
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // MARK: - Header

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Patients")
                            .font(.largeTitle.bold())

                        Text("GlaucoScan patient records")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                // MARK: - Patient List

                if viewModel.patients.isEmpty {
                    ContentUnavailableView(
                        "No Patients",
                        systemImage: "person.crop.rectangle.stack",
                        description: Text(
                            "Add a patient to get started."
                        )
                    )
                    .frame(maxHeight: .infinity)

                } else {
                    List {
                        ForEach(viewModel.patients) { patient in
                            NavigationLink {
                                PatientDetailView(
                                    patient: patient,
                                    sessionStore: sessionStore
                                )
                            } label: {
                                PatientCard(
                                    patient: patient
                                )
                            }
                        }
                        .onDelete(
                            perform: viewModel.deletePatient
                        )
                    }
                    .listStyle(.plain)
                }

                // MARK: - Add Patient Button

                Button {
                    showingAddPatient = true
                } label: {
                    Label(
                        "Add Patient",
                        systemImage: "plus"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)

            // MARK: - Add Patient Sheet

            .sheet(isPresented: $showingAddPatient) {
                AddPatientView(store: store)
            }

            // MARK: - Error Alert

            .alert(
                "Unable to complete action",
                isPresented: Binding(
                    get: {
                        viewModel.errorMessage != nil
                    },
                    set: {
                        if !$0 {
                            viewModel.errorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(
                    viewModel.errorMessage
                    ?? "Please try again."
                )
            }
        }
        .preferredColorScheme(.light)
    }
}
