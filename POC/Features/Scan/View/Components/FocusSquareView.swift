//
//  FocusSquareView.swift
//  POC
//
//  Created by Alessandro Moreno Lawadinata on 20/10/26.
//

import SwiftUI

struct FocusSquareView: View {
    let color: Color
    @State private var scale: CGFloat = 1.3
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .stroke(color, lineWidth: 1.5)
                .frame(width: 68, height: 68)
            
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear{
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeOut(duration: 0.35).delay(1.2)) {
                opacity = 0.0
            }
        }
    }
}
