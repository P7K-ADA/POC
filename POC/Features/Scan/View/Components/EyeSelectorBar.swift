//
//  EyeSelectorBar.swift
//  POC
//
//  Created by Alessandro Moreno Lawadinata on 20/10/26.
//

import SwiftUI

struct EyeSelectorBar: View {
    @Binding var selectedEye: EyeSide
    let isRightCaptured: Bool
    let isLeftCaptured: Bool
    let mintColor: Color
    
    var body: some View {
        HStack(spacing: 8){
            eyeButton(
                side: .left,
                title: "Left Eye (OS)",
                isCaptured: isRightCaptured
            )
            
            eyeButton(
                side: .right,
                title: "Right Eye (OD)",
                isCaptured: isLeftCaptured
            )
        }
        .padding(4)
                .background(Color.black.opacity(0.45))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
    }
    
    @ViewBuilder
    private func eyeButton(
        side: EyeSide,
        title: String,
        isCaptured: Bool
    ) -> some View {
        let isSelected = selectedEye == side
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedEye = side
            }
        } label: {
            HStack(spacing: 6){
                if isCaptured {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isSelected ? Color.black : mintColor)
                }
                else {
                    Image(systemName: "eye")
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSelected ? mintColor : Color.clear)
                        .foregroundStyle(isSelected ? Color.black : Color.white)
                        .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        EyeSelectorBar(
            selectedEye: .constant(.left),
            isRightCaptured: false,
            isLeftCaptured: true,
            mintColor: Color(red: 0.66, green: 0.91, blue: 0.83)
        )
    }
}
