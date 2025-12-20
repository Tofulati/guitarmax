//
//  CameraView.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        if let previewLayer = cameraManager.previewLayer, uiView.previewLayer == nil {
            uiView.previewLayer = previewLayer
            previewLayer.frame = uiView.bounds
            uiView.layer.addSublayer(previewLayer)
        }
        
        // Update frame when view size changes
        if let previewLayer = cameraManager.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}

class CameraPreviewView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
