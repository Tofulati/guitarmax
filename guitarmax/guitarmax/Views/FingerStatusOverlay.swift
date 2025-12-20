//
//  FingerStatusOverlay.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import SwiftUI
import Vision

struct FingerStatusOverlay: View {
    let chord: GuitarChord
    let handPoints: [VNHumanHandPoseObservation.JointName: CGPoint]
    let fingerStatus: [Int: FingerStatus]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw circles at detected fingertip positions with status colors
                ForEach(getFingertipsToTrack(), id: \.finger) { item in
                    if let tipPosition = handPoints[item.joint] {
                        let status = fingerStatus[item.finger] ?? .missing
                        
                        Circle()
                            .stroke(getStatusColor(status), lineWidth: 4)
                            .fill(getStatusColor(status).opacity(0.3))
                            .frame(width: 50, height: 50)
                            .position(
                                x: tipPosition.x * geometry.size.width,
                                y: tipPosition.y * geometry.size.height
                            )
                            .overlay(
                                VStack(spacing: 2) {
                                    Text("\(item.finger)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    Image(systemName: getStatusIcon(status))
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                }
                                .shadow(color: .black, radius: 2)
                                .position(
                                    x: tipPosition.x * geometry.size.width,
                                    y: tipPosition.y * geometry.size.height
                                )
                            )
                    }
                }
                
                // Overall status message at top
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
        
        // Only track fingers that are required for this chord
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
