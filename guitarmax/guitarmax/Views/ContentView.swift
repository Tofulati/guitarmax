//
//  ContentView.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import SwiftUI
import Vision
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var audioManager = AudioManager()
    @StateObject private var guitarTracker = GuitarNeckTracker()
    
    @State private var selectedChord: GuitarChord = .C
    @State private var isLessonActive = false
    @State private var showChordDiagram = true
    @State private var fingerStatus: [Int: FingerStatus] = [:]
    @State private var showCalibrationGuide = false
    @State private var useAutoTracking = true
    
    // Manual calibration zone
    @State private var manualGuitarZone = GuitarZone(
        nutY: 0.2,
        fret4Y: 0.8,
        leftX: 0.3,
        rightX: 0.7
    )
    
    // IMPORTANT: Guitar zone dynamically updates based on mode
    private var currentGuitarZone: GuitarZone {
        if useAutoTracking {
            // Use tracked zone with actual detected fret/string positions
            if var zone = guitarTracker.detectedGuitarZone {
                zone.detectedFretPositions = guitarTracker.detectedFretLines
                zone.detectedStringPositions = guitarTracker.detectedStringLines
                return zone
            }
            return GuitarZone(
                nutY: 0.2,
                fret4Y: 0.8,
                leftX: 0.3,
                rightX: 0.7
            )
        }
        return manualGuitarZone
    }
    
    var body: some View {
        ZStack {
            // Camera view
            CameraView(cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)
            
            // Calibration guide overlay - ONLY in manual mode
            if showCalibrationGuide && !isLessonActive && !useAutoTracking {
                GuitarPositionGuide(guitarZone: manualGuitarZone)
            }
            
            // Show guitar tracking zone visualization during lesson
            if isLessonActive && useAutoTracking && guitarTracker.detectedGuitarZone != nil {
                GeometryReader { geometry in
                    let zone = currentGuitarZone
                    let rect = CGRect(
                        x: zone.leftX * geometry.size.width,
                        y: zone.nutY * geometry.size.height,
                        width: (zone.rightX - zone.leftX) * geometry.size.width,
                        height: (zone.fret4Y - zone.nutY) * geometry.size.height
                    )
                    
                    // Guitar zone outline
                    Rectangle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                    
                    // Detected fret lines (vertical)
                    ForEach(Array(guitarTracker.detectedFretLines.enumerated()), id: \.offset) { index, fretY in
                        Path { path in
                            let y = fretY * geometry.size.height
                            path.move(to: CGPoint(x: zone.leftX * geometry.size.width, y: y))
                            path.addLine(to: CGPoint(x: zone.rightX * geometry.size.width, y: y))
                        }
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                    }
                    
                    // Detected string lines (horizontal)
                    ForEach(Array(guitarTracker.detectedStringLines.enumerated()), id: \.offset) { index, stringX in
                        Path { path in
                            let x = stringX * geometry.size.width
                            path.move(to: CGPoint(x: x, y: zone.nutY * geometry.size.height))
                            path.addLine(to: CGPoint(x: x, y: zone.fret4Y * geometry.size.height))
                        }
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                    }
                }
            }
            
            // Finger position overlay - targets move with guitar!
            if isLessonActive && !showCalibrationGuide {
                SmartFingerOverlay(
                    chord: selectedChord,
                    handPoints: cameraManager.detectedHandPoints,
                    fingerStatus: fingerStatus,
                    guitarZone: currentGuitarZone  // This updates in real-time!
                )
            }
            
            // Main UI
            VStack {
                // Top bar - compact
                HStack {
                    Text(isLessonActive ? selectedChord.rawValue : "GuitarMax")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if !isLessonActive && !showCalibrationGuide {
                        Menu {
                            ForEach(GuitarChord.allCases, id: \.self) { chord in
                                Button(chord.rawValue) {
                                    selectedChord = chord
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedChord.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(15)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.4))
                .cornerRadius(12)
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                Spacer()
                
                // Small control buttons - right side only during lesson
                if isLessonActive && !showCalibrationGuide {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 8) {
                            // Auto/Manual toggle - small
                            Button(action: {
                                withAnimation {
                                    useAutoTracking.toggle()
                                    if useAutoTracking {
                                        guitarTracker.startTracking()
                                    } else {
                                        guitarTracker.stopTracking()
                                    }
                                }
                            }) {
                                Image(systemName: useAutoTracking ? "scope" : "hand.draw")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(useAutoTracking ? Color.green.opacity(0.8) : Color.orange.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            
                            // Diagram toggle - small
                            Button(action: {
                                withAnimation {
                                    showChordDiagram.toggle()
                                }
                            }) {
                                Image(systemName: showChordDiagram ? "eye.slash" : "eye")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.blue.opacity(0.8))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.trailing, 12)
                    }
                }
                
                Spacer()
                
                // Chord diagram - compact
                if isLessonActive && showChordDiagram && !showCalibrationGuide {
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(selectedChord.rawValue)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                ForEach([1, 2, 3, 4], id: \.self) { finger in
                                    if selectedChord.fingerPositions.contains(where: { $0.finger == finger }) {
                                        Circle()
                                            .fill(getFingerColor(finger))
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                Text("\(finger)")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                }
                            }
                        }
                        
                        CompactChordDiagramView(chord: selectedChord)
                            .frame(height: 120)
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    .padding(.horizontal, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Bottom controls - minimal
                VStack(spacing: 10) {
                    if showCalibrationGuide {
                        // Calibration mode
                        Button(action: {
                            withAnimation {
                                showCalibrationGuide = false
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                Text("Done")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    } else {
                        // Normal mode
                        Button(action: {
                            isLessonActive.toggle()
                            if isLessonActive {
                                cameraManager.startDetection()
                                audioManager.startListening()
                                if useAutoTracking {
                                    guitarTracker.startTracking()
                                }
                            } else {
                                cameraManager.stopDetection()
                                audioManager.stopListening()
                                guitarTracker.stopTracking()
                                fingerStatus = [:]
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: isLessonActive ? "stop.fill" : "play.fill")
                                    .font(.system(size: 16))
                                Text(isLessonActive ? "Stop" : "Start Lesson")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isLessonActive ? Color.red : Color.green)
                            .cornerRadius(12)
                        }
                        
                        // Settings row when not active
                        if !isLessonActive {
                            HStack(spacing: 8) {
                                Button(action: {
                                    withAnimation {
                                        useAutoTracking.toggle()
                                        if !useAutoTracking {
                                            guitarTracker.stopTracking()
                                        }
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: useAutoTracking ? "checkmark" : "")
                                            .font(.system(size: 10))
                                        Text("Auto")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(useAutoTracking ? Color.green.opacity(0.7) : Color.gray.opacity(0.5))
                                    .cornerRadius(8)
                                }
                                
                                if !useAutoTracking {
                                    Button(action: {
                                        withAnimation {
                                            showCalibrationGuide = true
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "viewfinder")
                                                .font(.system(size: 10))
                                            Text("Position")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.7))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.4))
                .cornerRadius(12)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            audioManager.checkPermissions()
            cameraManager.guitarTracker = guitarTracker
            // Start tracking immediately for preview
            guitarTracker.startTracking()
        }
        .onChange(of: cameraManager.detectedHandPoints) {
            if isLessonActive && !showCalibrationGuide {
                updateFingerStatus()
            }
        }
        .onChange(of: guitarTracker.detectedGuitarZone) {
            // When guitar position changes, update finger status
            if isLessonActive && !showCalibrationGuide {
                updateFingerStatus()
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
    
    private func updateFingerStatus() {
        fingerStatus = analyzeFingerPlacement(
            handPoints: cameraManager.detectedHandPoints,
            chord: selectedChord,
            guitarZone: currentGuitarZone  // Uses live guitar position!
        )
    }
    
    private func analyzeFingerPlacement(
        handPoints: [VNHumanHandPoseObservation.JointName: CGPoint],
        chord: GuitarChord,
        guitarZone: GuitarZone
    ) -> [Int: FingerStatus] {
        var status: [Int: FingerStatus] = [:]
        
        let fingerTips: [(finger: Int, joint: VNHumanHandPoseObservation.JointName)] = [
            (1, .indexTip),
            (2, .middleTip),
            (3, .ringTip),
            (4, .littleTip)
        ]
        
        for position in chord.fingerPositions where position.finger > 0 {
            let finger = position.finger
            
            guard let joint = fingerTips.first(where: { $0.finger == finger })?.joint,
                  let tipPosition = handPoints[joint] else {
                status[finger] = .missing
                continue
            }
            
            // Expected position updates with guitar movement!
            let expectedPos = guitarZone.getFingerPosition(fret: position.fret, string: position.string)
            
            let dx = tipPosition.x - expectedPos.x
            let dy = tipPosition.y - expectedPos.y
            let distance = sqrt(dx * dx + dy * dy)
            
            let tolerance: CGFloat = 0.08
            
            if distance < tolerance {
                status[finger] = .correct
            } else {
                status[finger] = .incorrect
            }
        }
        
        return status
    }
}

struct GuitarZone: Equatable {
    let nutY: CGFloat
    let fret4Y: CGFloat
    let leftX: CGFloat
    let rightX: CGFloat
    
    // New: use actual detected fret/string positions
    var detectedFretPositions: [CGFloat] = []
    var detectedStringPositions: [CGFloat] = []
    
    func getFingerPosition(fret: Int, string: Int) -> CGPoint {
        var y: CGFloat
        var x: CGFloat
        
        // Use actual fret positions if available
        if !detectedFretPositions.isEmpty && fret > 0 && fret <= detectedFretPositions.count {
            // Use detected fret position
            y = detectedFretPositions[fret - 1]
        } else {
            // Fallback to calculated position
            let fretRatio = CGFloat(fret) / 4.0
            y = nutY + (fret4Y - nutY) * fretRatio
        }
        
        // Use actual string positions if available
        if !detectedStringPositions.isEmpty && string >= 1 && string <= detectedStringPositions.count {
            // Use detected string position
            x = detectedStringPositions[string - 1]
        } else {
            // Fallback to calculated position
            let stringRatio = CGFloat(string - 1) / 5.0
            x = leftX + (rightX - leftX) * stringRatio
        }
        
        return CGPoint(x: x, y: y)
    }
    
    static func == (lhs: GuitarZone, rhs: GuitarZone) -> Bool {
        return lhs.nutY == rhs.nutY &&
               lhs.fret4Y == rhs.fret4Y &&
               lhs.leftX == rhs.leftX &&
               lhs.rightX == rhs.rightX
    }
}

enum FingerStatus {
    case correct
    case incorrect
    case missing
}
