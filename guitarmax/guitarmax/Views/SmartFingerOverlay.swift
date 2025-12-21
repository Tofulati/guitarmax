//
//  SmartFingerOverlay.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import SwiftUI
import Vision
import AVFoundation

struct SmartFingerOverlay: View {
    let chord: GuitarChord
    let handPoints: [VNHumanHandPoseObservation.JointName: CGPoint]
    let fingerStatus: [Int: FingerStatus]
    let guitarZone: GuitarZone
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw target positions (yellow circles) on guitar
                ForEach(Array(chord.fingerPositions.enumerated()), id: \.offset) { index, position in
                    if position.fret > 0 {
                        let targetPos = guitarZone.getFingerPosition(fret: position.fret, string: position.string)
                        let x = targetPos.x * geometry.size.width
                        let y = targetPos.y * geometry.size.height
                        
                        Circle()
                            .stroke(Color.yellow, lineWidth: 4)
                            .fill(Color.yellow.opacity(0.3))
                            .frame(width: 55, height: 55)
                            .position(x: x, y: y)
                            .overlay(
                                VStack(spacing: 2) {
                                    Text("\(position.finger)")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("F\(position.fret)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .shadow(color: .black, radius: 2)
                                .position(x: x, y: y)
                            )
                    }
                }
                
                // Draw detected fingertips with status
                ForEach(getFingertipsToTrack(), id: \.finger) { item in
                    if let tipPosition = handPoints[item.joint] {
                        let status = fingerStatus[item.finger] ?? .missing
                        let x = tipPosition.x * geometry.size.width
                        let y = tipPosition.y * geometry.size.height
                        
                        Circle()
                            .stroke(getStatusColor(status), lineWidth: 4)
                            .fill(getStatusColor(status).opacity(0.3))
                            .frame(width: 42, height: 42)
                            .position(x: x, y: y)
                            .overlay(
                                VStack(spacing: 0) {
                                    Text("\(item.finger)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    Image(systemName: getStatusIcon(status))
                                        .font(.system(size: 10))
                                        .foregroundColor(.white)
                                }
                                .shadow(color: .black, radius: 2)
                                .position(x: x, y: y)
                            )
                    }
                }
                
                // Status message at top
                VStack {
                    HStack(spacing: 12) {
                        let correctCount = fingerStatus.values.filter { $0 == .correct }.count
                        let totalRequired = chord.fingerPositions.filter { $0.finger > 0 }.count
                        
                        if correctCount == totalRequired && totalRequired > 0 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Perfect! All fingers in position ✓")
                                .fontWeight(.semibold)
                        } else {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.orange)
                            Text("\(correctCount)/\(totalRequired) fingers correct")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(20)
                    .padding(.top, 80)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func getFingertipsToTrack() -> [(finger: Int, joint: VNHumanHandPoseObservation.JointName)] {
        let allFingers: [(Int, VNHumanHandPoseObservation.JointName)] = [
            (1, .indexTip),
            (2, .middleTip),
            (3, .ringTip),
            (4, .littleTip)
        ]
        
        let requiredFingers = Set(chord.fingerPositions.filter { $0.finger > 0 }.map { $0.finger })
        return allFingers.filter { requiredFingers.contains($0.0) }
    }
    
    private func getStatusColor(_ status: FingerStatus) -> Color {
        switch status {
        case .correct: return .green
        case .incorrect: return .red
        case .missing: return .orange
        }
    }
    
    private func getStatusIcon(_ status: FingerStatus) -> String {
        switch status {
        case .correct: return "checkmark"
        case .incorrect: return "xmark"
        case .missing: return "questionmark"
        }
    }
}
