//
//  ContentView.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import SwiftUI
import Vision

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var audioManager = AudioManager()
    
    @State private var selectedChord: GuitarChord = .C
    @State private var isLessonActive = false
    @State private var showChordDiagram = true
    @State private var fingerStatus: [Int: FingerStatus] = [:]
    
    var body: some View {
        ZStack {
            CameraView(cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)
            
            // Finger position indicators overlaid on camera
            if isLessonActive {
                FingerStatusOverlay(
                    chord: selectedChord,
                    handPoints: cameraManager.detectedHandPoints,
                    fingerStatus: fingerStatus
                )
            }
            
            VStack {
                // Top bar
                HStack {
                    Text(isLessonActive ? selectedChord.rawValue : "Learn Guitar")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if !isLessonActive {
                        Menu {
                            ForEach(GuitarChord.allCases, id: \.self) { chord in
                                Button(chord.rawValue) {
                                    selectedChord = chord
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedChord.rawValue)
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.down")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(20)
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(15)
                
                Spacer()
                
                // Chord diagram toggle (top right, non-intrusive)
                if isLessonActive {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                showChordDiagram.toggle()
                            }
                        }) {
                            Image(systemName: showChordDiagram ? "eye.slash.fill" : "eye.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Chord diagram (bottom, collapsible)
                if isLessonActive && showChordDiagram {
                    VStack(spacing: 10) {
                        HStack {
                            Text("\(selectedChord.rawValue) Chord")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Finger status indicators
                            HStack(spacing: 8) {
                                ForEach([1, 2, 3, 4], id: \.self) { finger in
                                    if selectedChord.fingerPositions.contains(where: { $0.finger == finger }) {
                                        Circle()
                                            .fill(getFingerColor(finger))
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                Text("\(finger)")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                }
                            }
                        }
                        
                        CompactChordDiagramView(chord: selectedChord)
                            .frame(height: 150)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Bottom controls
                VStack(spacing: 15) {
                    Button(action: {
                        isLessonActive.toggle()
                        if isLessonActive {
                            cameraManager.startDetection()
                            audioManager.startListening()
                        } else {
                            cameraManager.stopDetection()
                            audioManager.stopListening()
                            fingerStatus = [:]
                        }
                    }) {
                        HStack {
                            Image(systemName: isLessonActive ? "stop.fill" : "play.fill")
                            Text(isLessonActive ? "Stop Lesson" : "Start Lesson")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLessonActive ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    
                    if !isLessonActive {
                        Text("Position camera to see your fretting hand\nFrets run horizontally • Strings run vertically")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(15)
            }
            .padding()
        }
        .onAppear {
            audioManager.checkPermissions()
        }
        .onChange(of: cameraManager.detectedHandPoints) {
            if isLessonActive {
                fingerStatus = analyzeFingerPlacement(
                    handPoints: cameraManager.detectedHandPoints,
                    chord: selectedChord
                )
            }
        }
    }
    
    private func getFingerColor(_ finger: Int) -> Color {
        if let status = fingerStatus[finger] {
            switch status {
            case .correct: return .green
            case .incorrect: return .red
            case .missing: return .orange
            }
        }
        return .gray
    }
    
    private func analyzeFingerPlacement(
        handPoints: [VNHumanHandPoseObservation.JointName: CGPoint],
        chord: GuitarChord
    ) -> [Int: FingerStatus] {
        var status: [Int: FingerStatus] = [:]
        
        // Get the fingertip positions we need
        let fingerTips: [(finger: Int, joint: VNHumanHandPoseObservation.JointName)] = [
            (1, .indexTip),
            (2, .middleTip),
            (3, .ringTip),
            (4, .littleTip)
        ]
        
        // Check each required finger for the chord
        for position in chord.fingerPositions where position.finger > 0 {
            let finger = position.finger
            
            // Find the corresponding fingertip
            guard let joint = fingerTips.first(where: { $0.finger == finger })?.joint,
                  let tipPosition = handPoints[joint] else {
                status[finger] = .missing
                continue
            }
            
            // Define expected regions (simplified, no calibration needed)
            // Frets run horizontally: 0.2-0.8 (left to right)
            // Strings run vertically: 0.2-0.8 (top to bottom)
            
            let expectedFretX = 0.2 + (0.6 * CGFloat(position.fret) / 4.0)
            let expectedStringY = 0.2 + (0.6 * CGFloat(6 - position.string) / 5.0)
            
            // Check if finger is within tolerance (±0.15 range)
            let tolerance: CGFloat = 0.15
            let fretMatch = abs(tipPosition.x - expectedFretX) < tolerance
            let stringMatch = abs(tipPosition.y - expectedStringY) < tolerance
            
            if fretMatch && stringMatch {
                status[finger] = .correct
            } else {
                status[finger] = .incorrect
            }
        }
        
        return status
    }
}

enum FingerStatus {
    case correct
    case incorrect
    case missing
}
