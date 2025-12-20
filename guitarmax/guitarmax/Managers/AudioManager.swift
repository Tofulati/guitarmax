//
//  AudioManager.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import AVFoundation
import SwiftUI
import Combine

class AudioManager: NSObject, ObservableObject {
    @Published var detectedPitch: Float = 0.0
    @Published var detectedNotes: [String] = []
    
    private var audioEngine: AVAudioEngine?
    private var isListening = false
    
    func checkPermissions() {
        AVAudioApplication.requestRecordPermission { granted in
            if granted {
                self.setupAudio()
            } else {
                print("Microphone access denied")
            }
        }
    }
    
    private func setupAudio() {
        audioEngine = AVAudioEngine()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup error: \(error)")
        }
    }
    
    func startListening() {
        guard let audioEngine = audioEngine else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            print("Audio engine start error: \(error)")
        }
    }
    
    func stopListening() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        isListening = false
        
        DispatchQueue.main.async {
            self.detectedPitch = 0.0
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frames = buffer.frameLength
        
        var sum: Float = 0
        for i in 0..<Int(frames) {
            sum += abs(channelData[0][i])
        }
        let average = sum / Float(frames)
        
        DispatchQueue.main.async {
            self.detectedPitch = average * 1000
        }
    }
}
