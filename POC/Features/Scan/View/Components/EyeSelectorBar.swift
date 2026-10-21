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
        HStack(spacing: 28) {
            eyeButton(
                side: .left,
                title: "Left Eye",
                isCaptured: isLeftCaptured
            )

            eyeButton(
                side: .right,
                title: "Right Eye",
                isCaptured: isRightCaptured
            )
        }
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
                        .foregroundStyle(isSelected ? Color.primary : mintColor)
                }
                else {
                    Image(systemName: "eye")
                        .font(.caption)
                }
                Text(title)
                    .font(.body.weight(isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
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
