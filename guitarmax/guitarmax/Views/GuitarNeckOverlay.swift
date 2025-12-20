//
//  GuitarNeckOverlay.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import SwiftUI

struct GuitarNeckOverlay: View {
    let chord: GuitarChord
    @Binding var overlayCalibration: OverlayCalibration?
    @Binding var isCalibrating: Bool
    @Binding var calibrationPoints: [CGPoint]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isCalibrating {
                    // Calibration mode UI
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 15) {
                            Text("Tap 4 Corners of Guitar Neck")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                CalibrationStep(
                                    number: 1,
                                    text: "Nut, Low E (thick string, left)",
                                    completed: calibrationPoints.count > 0
                                )
                                CalibrationStep(
                                    number: 2,
                                    text: "4th Fret, Low E (thick string, right)",
                                    completed: calibrationPoints.count > 1
                                )
                                CalibrationStep(
                                    number: 3,
                                    text: "4th Fret, High E (thin string, right)",
                                    completed: calibrationPoints.count > 2
                                )
                                CalibrationStep(
                                    number: 4,
                                    text: "Nut, High E (thin string, left)",
                                    completed: calibrationPoints.count > 3
                                )
                            }
                            
                            if calibrationPoints.count == 4 {
                                Button(action: {
                                    completeCalibration(in: geometry.size)
                                }) {
                                    Text("✓ Done")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green)
                                        .cornerRadius(10)
                                }
                            }
                            
                            Button(action: {
                                calibrationPoints = []
                            }) {
                                Text("Reset")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color.red.opacity(0.7))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(15)
                        .padding()
                        
                        Spacer()
                    }
                    
                    // Show calibration points with larger circles
                    ForEach(Array(calibrationPoints.enumerated()), id: \.offset) { index, point in
                        Circle()
                            .stroke(Color.green, lineWidth: 3)
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .position(point)
                            .overlay(
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .position(point)
                            )
                    }
                    
                    // Draw lines between points to visualize the guitar neck area
                    if calibrationPoints.count >= 2 {
                        Path { path in
                            for i in 0..<calibrationPoints.count {
                                if i == 0 {
                                    path.move(to: calibrationPoints[i])
                                } else {
                                    path.addLine(to: calibrationPoints[i])
                                }
                            }
                            if calibrationPoints.count == 4 {
                                path.addLine(to: calibrationPoints[0])
                            }
                        }
                        .stroke(Color.green.opacity(0.5), lineWidth: 2)
                    }
                    
                } else if let calibration = overlayCalibration {
                    // Show finger positions overlay
                    ForEach(Array(chord.fingerPositions.enumerated()), id: \.offset) { index, position in
                        if position.fret > 0 {
                            let stringY = calibration.getStringY(for: position.string, in: geometry.size)
                            let fretX = calibration.getFretX(for: position.fret, in: geometry.size)
                            
                            // Larger, more visible circles
                            Circle()
                                .stroke(Color.yellow, lineWidth: 5)
                                .fill(Color.yellow.opacity(0.4))
                                .frame(width: 60, height: 60)
                                .position(x: fretX, y: stringY)
                                .overlay(
                                    VStack(spacing: 2) {
                                        Text("\(position.finger)")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white)
                                        Text(getFingerName(position.finger))
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    .shadow(color: .black, radius: 3)
                                    .position(x: fretX, y: stringY)
                                )
                        }
                    }
                    
                    // Show fret labels for reference
                    ForEach(1...4, id: \.self) { fret in
                        let fretX = calibration.getFretX(for: fret, in: geometry.size)
                        let midY = geometry.size.height / 2
                        
                        Text("\(fret)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                            .position(x: fretX, y: midY)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    if isCalibrating && calibrationPoints.count < 4 {
                        calibrationPoints.append(value.location)
                    }
                }
        )
    }
    
    private func completeCalibration(in size: CGSize) {
        guard calibrationPoints.count == 4 else { return }
        
        // Convert points to normalized coordinates
        let normalizedPoints = calibrationPoints.map { point in
            CGPoint(x: point.x / size.width, y: point.y / size.height)
        }
        
        // Create calibration from the 4 points
        let newCalibration = OverlayCalibration(
            topLeft: normalizedPoints[0],
            topRight: normalizedPoints[1],
            bottomRight: normalizedPoints[2],
            bottomLeft: normalizedPoints[3]
        )
        
        overlayCalibration = newCalibration
        isCalibrating = false
        calibrationPoints = []
    }
    
    private func getFingerName(_ finger: Int) -> String {
        switch finger {
        case 1: return "Index"
        case 2: return "Middle"
        case 3: return "Ring"
        case 4: return "Pinky"
        default: return ""
        }
    }
}

struct CalibrationStep: View {
    let number: Int
    let text: String
    let completed: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(completed ? Color.green : Color.white.opacity(0.3))
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(number)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(completed ? .white : .white.opacity(0.5))
                )
            
            Text(text)
                .font(.caption)
                .foregroundColor(completed ? .white : .white.opacity(0.7))
        }
    }
}

// Enhanced calibration with perspective transform
struct OverlayCalibration {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomRight: CGPoint
    let bottomLeft: CGPoint
    
    // Calculate X position for a given fret using perspective
    func getFretX(for fret: Int, in size: CGSize) -> CGFloat {
        // Fret position ratio (0.0 at nut, 1.0 at 4th fret)
        let fretRatio = CGFloat(fret) / 4.0
        
        // Top edge interpolation (low E side)
        let topX = topLeft.x + (topRight.x - topLeft.x) * fretRatio
        
        // Bottom edge interpolation (high E side)
        let bottomX = bottomLeft.x + (bottomRight.x - bottomLeft.x) * fretRatio
        
        // Average between top and bottom
        let normalizedX = (topX + bottomX) / 2.0
        
        return normalizedX * size.width
    }
    
    // Calculate Y position for a given string using perspective
    func getStringY(for string: Int, in size: CGSize) -> CGFloat {
        // String 6 = low E (top), String 1 = high E (bottom)
        // Calculate ratio: string 6 -> 0.0, string 1 -> 1.0
        let stringRatio = CGFloat(6 - string) / 5.0
        
        // Left edge interpolation (nut side)
        let leftY = topLeft.y + (bottomLeft.y - topLeft.y) * stringRatio
        
        // Right edge interpolation (4th fret side)
        let rightY = topRight.y + (bottomRight.y - topRight.y) * stringRatio
        
        // Average between left and right
        let normalizedY = (leftY + rightY) / 2.0
        
        return normalizedY * size.height
    }
    
    // Default calibration for initial setup
    static let defaultCalibration = OverlayCalibration(
        topLeft: CGPoint(x: 0.15, y: 0.25),
        topRight: CGPoint(x: 0.75, y: 0.25),
        bottomRight: CGPoint(x: 0.75, y: 0.75),
        bottomLeft: CGPoint(x: 0.15, y: 0.75)
    )
}
