//
//  ScanCameraView.swift
//  POC
//

import SwiftUI
import UIKit

struct ScanCameraView: View {
    @ObservedObject var camera: CameraService
    let selectedEye: EyeSide
    let tint: Color
    let onCapturedImage: (UIImage) -> Void

    @State private var focusPoint: CGPoint?
    @State private var focusID = UUID()
    @State private var baseZoom: CGFloat = 1

    var body: some View {
        VStack(spacing: 18) {
            ScanHeaderView(selectedEye: selectedEye)

            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.black)

                    CameraPreview(session: camera.session)
                        .clipShape(RoundedRectangle(cornerRadius: 24))

                    Circle()
                        .stroke(
                            .black.opacity(0.85),
                            style: StrokeStyle(lineWidth: 1, dash: [10, 10])
                        )
                        .frame(width: 240, height: 240)

                    if let focusPoint {
                        FocusSquareView(color: tint)
                            .position(focusPoint)
                            .id(focusID)
                    }

                    ScanAlignmentHint()
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    focusPoint = location
                    focusID = UUID()

                    let devicePoint = CGPoint(
                        x: location.y / geometry.size.height,
                        y: 1 - (location.x / geometry.size.width)
                    )
                    camera.focus(at: devicePoint)
                }
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            camera.setZoom(factor: baseZoom * value)
                        }
                        .onEnded { _ in
                            baseZoom = camera.currentZoomFactor
                        }
                )
            }
            .aspectRatio(6 / 7, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            CameraStatusView(
                status: camera.status,
                errorMessage: camera.errorMessage
            )

            CameraZoomControl(camera: camera)

            Button {
                camera.capturePhoto()
            } label: {
                Circle()
                    .fill(tint)
                    .frame(width: 76, height: 76)
                    .overlay {
                        Circle()
                            .stroke(.black, lineWidth: 4)
                            .padding(6)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Capture photo")

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .onAppear {
            camera.start()
        }
        .onChange(of: camera.capturedImage) { _, image in
            guard let image else { return }
            onCapturedImage(image)
        }
    }
}

private struct ScanHeaderView: View {
    let selectedEye: EyeSide

    var body: some View {
        Text(selectedEye == .left ? "Left Eye" : "Right Eye")
            .font(.title2.weight(.bold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
    }
}

private struct ScanAlignmentHint: View {
    var body: some View {
        VStack {
            Spacer()

            Text("ALIGN EYE TO TARGET")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.secondary.opacity(0.35), lineWidth: 1)
                }
                .padding(.bottom, 20)
        }
    }
}

private struct CameraStatusView: View {
    let status: String
    let errorMessage: String?

    var body: some View {
        VStack(spacing: 4) {
            if !status.isEmpty {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private struct CameraZoomControl: View {
    @ObservedObject var camera: CameraService

    var body: some View {
        HStack(spacing: 12) {
            Text("1x")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            Slider(
                value: Binding(
                    get: { camera.currentZoomFactor },
                    set: { camera.setZoom(factor: $0) }
                ),
                in: camera.minZoom...camera.maxZoom
            )
            .tint(.black)

            Text("4x")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}
