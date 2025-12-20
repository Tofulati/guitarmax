//
//  CompactChordDiagramView.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import SwiftUI

struct CompactChordDiagramView: View {
    let chord: GuitarChord
    
    var body: some View {
        GeometryReader { geometry in
            let stringSpacing = geometry.size.width / 6
            let fretHeight = geometry.size.height / 5
            
            ZStack {
                // Draw strings (vertical lines)
                ForEach(0..<6) { string in
                    Path { path in
                        let x = stringSpacing * CGFloat(string) + stringSpacing / 2
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    }
                    .stroke(Color.white, lineWidth: 2)
                }
                
                // Draw frets (horizontal lines)
                ForEach(0..<5) { fret in
                    Path { path in
                        let y = fretHeight * CGFloat(fret)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.white, lineWidth: fret == 0 ? 4 : 1.5)
                }
                
                // Draw string labels at bottom
                ForEach(0..<6) { string in
                    let stringNames = ["E", "A", "D", "G", "B", "e"]
                    Text(stringNames[string])
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .position(
                            x: stringSpacing * CGFloat(string) + stringSpacing / 2,
                            y: geometry.size.height + 15
                        )
                }
                
                // Draw finger positions
                ForEach(Array(chord.fingerPositions.enumerated()), id: \.offset) { index, position in
                    let xPos = stringSpacing * CGFloat(index) + stringSpacing / 2
                    let yPos = fretHeight * CGFloat(position.fret) - fretHeight / 2
                    
                    if position.fret > 0 {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 24, height: 24)
                            .position(x: xPos, y: yPos)
                            .overlay(
                                Text("\(position.finger)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .position(x: xPos, y: yPos)
                            )
                    } else if position.fret == 0 {
                        Text("O")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .position(x: xPos, y: -10)
                    } else {
                        Text("X")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .position(x: xPos, y: -10)
                    }
                }
            }
        }
        .padding(.vertical, 20)
    }
}
