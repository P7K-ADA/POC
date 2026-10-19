//
//  EyeSchematicView.swift
//  POC
//
//  Created by Harley Ganisson on 20/10/26.
//


import SwiftUI

/// Illustrative optic disc / cup drawing. Cup diameter = CDR x disc diameter.
/// Built from plain shapes so it also renders correctly through ImageRenderer.
struct EyeSchematicView: View {
    let side: EyeSide
    let cdr: Double?
    var showsCaption = true
    var aspectRatio: CGFloat = 1.1

    var body: some View {
        ZStack {
            Color(white: 0.09)

            GeometryReader { geo in
                let disc = min(geo.size.width, geo.size.height) * 0.64
                ZStack {
                    Circle()
                        .fill(Color(white: 0.27))
                        .overlay(Circle().stroke(Color.white.opacity(0.45), lineWidth: 1.5))
                        .frame(width: disc, height: disc)

                    if let cdr {
                        let cup = disc * CGFloat(min(max(cdr, 0), 1))
                        Circle()
                            .fill(Color(white: 0.88).opacity(0.92))
                            .frame(width: cup, height: cup)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }

            VStack {
                HStack {
                    Text(side.rawValue)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.7))
                    Spacer()
                }
                Spacer()
                if showsCaption {
                    Text("SCHEMATIC · OUTER DISC / INNER CUP")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(8)
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            cdr.map { "\(side.rawValue) schematic, vertical cup-to-disc ratio \(String(format: "%.2f", $0))" }
                ?? "\(side.rawValue) schematic, no measurement"
        )
    }
}