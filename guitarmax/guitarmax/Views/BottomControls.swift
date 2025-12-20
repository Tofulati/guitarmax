//
//  BottomControls.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import SwiftUI

struct BottomControls: View {
    @Binding var isLessonActive: Bool
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var cameraManager: CameraManager
    let selectedChord: GuitarChord
    
    var body: some View {
        VStack(spacing: 15) {
            Button(action: {
                isLessonActive.toggle()
                if isLessonActive {
                    cameraManager.startDetection()
                    audioManager.startListening()
                } else {
                    cameraManager.stopDetection()
                    audioManager.stopListening()
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
            
            if isLessonActive {
                Text("Position your hand on the \(selectedChord.rawValue) chord and strum")
                    .font(.caption)
                    .foregroundColor(.white)
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
}
