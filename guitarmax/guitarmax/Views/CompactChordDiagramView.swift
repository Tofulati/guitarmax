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

                // Strings (low E → high e)
                ForEach(0..<6) { i in
                    let x = stringSpacing * CGFloat(i) + stringSpacing / 2
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    }
                    .stroke(Color.white, lineWidth: 2)
                }

                // Frets
                ForEach(0..<5) { fret in
                    let y = fretHeight * CGFloat(fret)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.white, lineWidth: fret == 0 ? 4 : 1.5)
                }

                // String labels
                let stringNames = ["E", "A", "D", "G", "B", "e"]
                ForEach(0..<6) { i in
                    Text(stringNames[i])
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .position(
                            x: stringSpacing * CGFloat(i) + stringSpacing / 2,
                            y: geometry.size.height + 14
                        )
                }

                // Finger positions
                ForEach(chord.fingerPositions.indices, id: \.self) { i in
                    let position = chord.fingerPositions[i]

                    // Convert string number (1–6) → view index (0–5)
                    let stringIndex = 6 - position.string
                    let x = stringSpacing * CGFloat(stringIndex) + stringSpacing / 2

                    if position.fret > 0 {
                        let y = fretHeight * (CGFloat(position.fret) - 0.5)

                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 22, height: 22)
                            .position(x: x, y: y)
                            .overlay(
                                Text("\(position.finger)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .position(x: x, y: y)
                            )

                    } else if position.fret == 0 {
                        Text("O")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .position(x: x, y: -10)

                    } else {
                        Text("X")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .position(x: x, y: -10)
                    }
                }
            }
        }
        .padding(.vertical, 20)
    }
}
