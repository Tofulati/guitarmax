//
//  CameraManager.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import AVFoundation
import Vision
import SwiftUI
import Combine

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    @Published var detectedHandPoints: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
    @Published var previewLayer: AVCaptureVideoPreviewLayer?

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let outputQueue = DispatchQueue(label: "camera.output.queue")

    private let detectionQueue = DispatchQueue(label: "handpose.detection.queue")
    private var isDetecting = false

    private var lastVisionTime: CFAbsoluteTime = 0
    private let visionFPS: Double = 15

    override init() {
        super.init()
        checkPermissions()
    }

    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupCamera()
                }
            }
        default:
            print("Camera access denied")
        }
    }

    private func setupCamera() {
        sessionQueue.async {
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high

            guard
                let device = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: .front
                ),
                let input = try? AVCaptureDeviceInput(device: device),
                self.captureSession.canAddInput(input)
            else {
                print("Failed to create camera input")
                self.captureSession.commitConfiguration()
                return
            }

            self.captureSession.addInput(input)

            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String:
                    kCVPixelFormatType_32BGRA
            ]
            self.videoOutput.alwaysDiscardsLateVideoFrames = true

            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
                self.videoOutput.setSampleBufferDelegate(self, queue: self.outputQueue)
                
                // Set video orientation to portrait
                if let connection = self.videoOutput.connection(with: .video) {
                    connection.videoRotationAngle = 90
                }
            }

            self.captureSession.commitConfiguration()
            
            // Create preview layer before starting session
            DispatchQueue.main.async {
                let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                layer.videoGravity = .resizeAspectFill
                
                // Set preview layer orientation
                if let connection = layer.connection {
                    connection.videoRotationAngle = 90
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = true
                }
                
                self.previewLayer = layer
                
                // Start session after preview layer is created
                self.sessionQueue.async {
                    self.captureSession.startRunning()
                }
            }
        }
    }

    func startDetection() {
        detectionQueue.sync {
            isDetecting = true
        }
    }

    func stopDetection() {
        detectionQueue.sync {
            isDetecting = false
        }
        Task { @MainActor in
            detectedHandPoints = [:]
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let detecting = detectionQueue.sync { isDetecting }
        guard detecting else { return }

        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastVisionTime > 1.0 / visionFPS else { return }
        lastVisionTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        
        // Create handler with proper orientation
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )

        do {
            try handler.perform([request])

            guard let observation = request.results?.first else {
                Task { @MainActor in
                    self.detectedHandPoints = [:]
                }
                return
            }
            
            let recognizedPoints = try observation.recognizedPoints(.all)

            var points: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]

            // Vision framework coordinates are normalized (0-1)
            // Origin is bottom-left, we need to flip Y for screen coordinates
            // Also flip X for mirrored front camera
            for (joint, point) in recognizedPoints where point.confidence > 0.3 {
                points[joint] = CGPoint(
                    x: 1 - point.location.x,
                    y: 1 - point.location.y
                )
            }

            Task { @MainActor in
                self.detectedHandPoints = points
            }

        } catch {
            print("Hand pose detection failed:", error)
        }
    }
    
    deinit {
        captureSession.stopRunning()
    }
}
