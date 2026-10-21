//
//  AddPatientView.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//

import SwiftUI
import SwiftData

struct AddPatientView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddPatientViewModel
    @State private var showingFAQ = false

    init(store: PatientStore) {
        _viewModel = StateObject(
            wrappedValue: AddPatientViewModel(store: store)
        )
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                PatientRegistrationHeader(
                    onBack: { dismiss() },
                    onFAQ: { showingFAQ = true }
                )

                Form {
                    ExaminationSessionSection()
                    
                    PatientInformationSection(
                        name: $viewModel.name,
                        dateOfBirth: $viewModel.dateOfBirth,
                        selectedSex: $viewModel.selectedSex
                    )

                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
            }
            .padding(.horizontal, 5)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PatientSubmitButton {
                viewModel.savePatient()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: viewModel.didSave) { _, didSave in
            if didSave {
                dismiss()
            }
        }
        .alert(
            "Check Patient Information",
            isPresented: errorAlertPresented
        ) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "Please check the fields.")
        }
        .alert("FAQ", isPresented: $showingFAQ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Patient registration help will be available here.")
        }
        .preferredColorScheme(.light)
    }

    private var errorAlertPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: {
                if !$0 {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}

#Preview("Patient Registration") {
    NavigationStack {
        AddPatientView(
            store: PatientStore(
                modelContext: previewContainer.mainContext
            )
        )
    }
    .modelContainer(previewContainer)
}

@MainActor
private let previewContainer: ModelContainer = {
    let schema = Schema([
        PatientEntity.self,
        ScreeningSessionEntity.self,
        EyeExaminationEntity.self,
        AnalysisRunEntity.self,
        ReportEntity.self
    ])

    let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true
    )

    return try! ModelContainer(
        for: schema,
        configurations: [configuration]
    )
}()
