//
//  PatientDetailView.swift
//  POC
//
//  Created by Carolyn Santana on 18/10/26.
//


import SwiftUI

struct PatientDetailView: View {
    @StateObject private var viewModel: PatientDetailViewModel
    @State private var showingScan = false

    init(
        patient: Patient,
        sessionStore: ScreeningSessionStore
    ) {
        _viewModel = StateObject(
            wrappedValue: PatientDetailViewModel(
                patient: patient,
                sessionStore: sessionStore
            )
        )
    }

    var body: some View {
        List {
            Section("Patient Information") {
                detailRow("Name", value: viewModel.patient.name)

                detailRow(
                    "Age",
                    value: viewModel.patient.age.map {
                        "\($0)"
                    } ?? "Not specified"
                )

                detailRow(
                    "Sex",
                    value: viewModel.patient.sex?.rawValue
                        ?? "Not specified"
                )
            }

            Section("Screening Sessions") {
                if viewModel.sessions.isEmpty {
                    ContentUnavailableView(
                        "No Screening Sessions",
                        systemImage: "eye",
                        description: Text(
                            "Add a session to see its images and CDR."
                        )
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.sessions) { session in
                        ScreeningSessionCard(session: session)
                    }
                }

                Button {
                    showingScan = true
                } label: {
                    Label("Add Session", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Patient Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingScan) {
            ScanView(patientID: viewModel.patient.id) { session in
                viewModel.addSession(session)

                // Close scanner and return to Patient Detail.
                showingScan = false
            }
        }
        .preferredColorScheme(.light)
    }

    private func detailRow(
        _ title: String,
        value: String
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct ScreeningSessionCard: View {
    let session: ScreeningSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                session.examDate.formatted(
                    date: .abbreviated,
                    time: .shortened
                )
            )
            .font(.headline)

            Text(session.status.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)

            eyeSection(session.leftEye)

            Divider()

            eyeSection(session.rightEye)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func eyeSection(
        _ eye: EyeExaminationRecord
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(eye.eyeSide.rawValue)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if eye.isDummy {
                    Text("Placeholder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let image = eye.image {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()

                    if let result = eye.segmentationResult,
                       let overlay = SegmentationOverlay.makeImage(
                           from: result
                       ) {
                        Image(uiImage: overlay)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(maxHeight: 180)
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .clipShape(
                    RoundedRectangle(cornerRadius: 8)
                )
            } else {
                Label(
                    "Image not captured yet",
                    systemImage: "eye"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }

            HStack {
                Text("Vertical CDR")
                    .foregroundStyle(.secondary)

                Spacer()

                if let cdr = eye.verticalCDR {
                    Text(String(format: "%.3f", cdr))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                } else {
                    Text("—")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
        }
    }
}
