//
//  GuitarPositionGuide.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import SwiftUI

struct GuitarPositionGuide: View {
    let guitarZone: GuitarZone
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent overlay
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                
                // Guitar positioning rectangle
                let rect = CGRect(
                    x: guitarZone.leftX * geometry.size.width,
                    y: guitarZone.nutY * geometry.size.height,
                    width: (guitarZone.rightX - guitarZone.leftX) * geometry.size.width,
                    height: (guitarZone.fret4Y - guitarZone.nutY) * geometry.size.height
                )
                
                // Main positioning rectangle
                Rectangle()
                    .stroke(style: StrokeStyle(lineWidth: 3, dash: [10, 5]))
                    .foregroundColor(.yellow)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                
                // Corner markers
                ForEach(0..<4) { corner in
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                        .position(getCornerPosition(corner, in: rect))
                }
                
                // Fret labels (vertical, left side)
                VStack(spacing: rect.height / 4 - 10) {
                    ForEach(0...4, id: \.self) { fret in
                        Text(fret == 0 ? "Nut" : "F\(fret)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.yellow)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                    }
                }
                .position(x: rect.minX - 35, y: rect.midY)
                
                // String labels (horizontal, bottom)
                HStack(spacing: rect.width / 5 - 15) {
                    ForEach([6, 5, 4, 3, 2, 1], id: \.self) { string in
                        Text("S\(string)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.yellow)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                    }
                }
                .position(x: rect.midX, y: rect.maxY + 30)
                
                // Title at top
                Text("Position Guitar Neck Here")
                    .font(.headline)
                    .foregroundColor(.yellow)
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .position(x: rect.midX, y: rect.minY - 30)
                
                // Instructions at bottom
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "guitars.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        Text("Position your guitar neck within the yellow frame")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Phone in LANDSCAPE (volume buttons down)")
                            }
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Frets run vertically (TOP → BOTTOM)")
                            }
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Strings run horizontally (LEFT → RIGHT)")
                            }
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Keep guitar stable during lesson")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                    .padding()
                }
            }
        }
    }
    
    private func getCornerPosition(_ corner: Int, in rect: CGRect) -> CGPoint {
        switch corner {
        case 0: return CGPoint(x: rect.minX, y: rect.minY) // Top-left
        case 1: return CGPoint(x: rect.maxX, y: rect.minY) // Top-right
        case 2: return CGPoint(x: rect.maxX, y: rect.maxY) // Bottom-right
        case 3: return CGPoint(x: rect.minX, y: rect.maxY) // Bottom-left
        default: return .zero
        }
    }
}
