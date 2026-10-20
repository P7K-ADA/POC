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

    init() {
        let store = PatientStore()

        _store = StateObject(wrappedValue: store)
        _viewModel = StateObject(
            wrappedValue: PatientListViewModel(store: store)
        )
        _sessionStore = StateObject(
            wrappedValue: ScreeningSessionStore()
        )
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                patientContent
                bottomBar
            }
            .padding(.horizontal, 5)
            .toolbar(.hidden, for: .navigationBar)
            .alert(
                "Unable to Complete Action",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.clearError() } }
                )
            ) {
                Button("OK", role: .cancel) {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }.background(Color(uiColor: .systemGroupedBackground))
    }

    private var header: some View {
        Text("Patient")
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
    }

    @ViewBuilder
    private var patientContent: some View {
        if viewModel.patients.isEmpty {
            PatientEmptyStateView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.filteredPatients.isEmpty {
            ContentUnavailableView.search(
                text: viewModel.searchText
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(viewModel.filteredPatients) { patient in
                    NavigationLink {
                        PatientDetailView(
                            patient: patient,
                            sessionStore: sessionStore
                        )
                    } label: {
                        PatientCard(patient: patient)
                    }
                }
                .onDelete(perform: viewModel.deletePatients)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .contentMargins(.vertical, 0)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            PatientSearchBar(text: $viewModel.searchText)

            NavigationLink {
                AddPatientView(store: store)
            } label: {
                AddPatientButton()
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
