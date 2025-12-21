//
//  GuitarNeckTracker.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import Foundation
import Vision
import AVFoundation
import Combine
import CoreImage

class GuitarNeckTracker: ObservableObject {
    @Published var detectedGuitarZone: GuitarZone?
    @Published var detectedFretLines: [CGFloat] = []  // Y positions of frets
    @Published var detectedStringLines: [CGFloat] = []  // X positions of strings
    @Published var isTracking = false
    
    private let detectionQueue = DispatchQueue(label: "guitar.detection.queue")
    private var lastDetectionTime: CFAbsoluteTime = 0
    private let detectionFPS: Double = 15
    
    // Smoothing
    private var recentZones: [GuitarZone] = []
    private var recentFretLines: [[CGFloat]] = []
    private var recentStringLines: [[CGFloat]] = []
    private let smoothingWindowSize = 3
    
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        guard isTracking else { return }
        
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastDetectionTime > 1.0 / detectionFPS else { return }
        lastDetectionTime = now
        
        detectGuitarComponents(in: pixelBuffer)
    }
    
    private func detectGuitarComponents(in pixelBuffer: CVPixelBuffer) {
        // Strategy 1: Detect guitar neck region
        let rectRequest = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self,
                  let results = request.results as? [VNRectangleObservation] else {
                return
            }
            
            if let guitarRect = self.findGuitarNeckRectangle(from: results) {
                let zone = self.convertToGuitarZone(guitarRect)
                self.addZoneToSmoothingBuffer(zone)
            }
        }
        
        rectRequest.minimumAspectRatio = 0.15
        rectRequest.maximumAspectRatio = 1.2
        rectRequest.minimumSize = 0.1
        rectRequest.maximumObservations = 15
        rectRequest.minimumConfidence = 0.2
        
        // Strategy 2: Detect lines (frets and strings)
        let lineRequest = VNDetectHorizonRequest()
        
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )
        
        // Also detect edges for fret/string detection
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.detectFretsAndStrings(pixelBuffer)
        }
        
        do {
            try handler.perform([rectRequest])
        } catch {
            print("Guitar detection failed:", error)
        }
    }
    
    private func detectFretsAndStrings(_ pixelBuffer: CVPixelBuffer) {
        // Convert to CIImage for processing
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Apply edge detection
        guard let edgeFilter = CIFilter(name: "CIEdges") else { return }
        edgeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(2.0, forKey: kCIInputIntensityKey)
        
        guard let edgeOutput = edgeFilter.outputImage else { return }
        
        // Detect lines using Hough transform approximation
        let lineRequest = VNDetectContoursRequest { [weak self] request, error in
            guard let self = self,
                  let results = request.results as? [VNContoursObservation] else {
                return
            }
            
            self.analyzeContoursForFretsAndStrings(results)
        }
        
        lineRequest.contrastAdjustment = 3.0
        lineRequest.detectsDarkOnLight = true
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(edgeOutput, from: edgeOutput.extent) else { return }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([lineRequest])
        } catch {
            print("Line detection failed:", error)
        }
    }
    
    private func analyzeContoursForFretsAndStrings(_ observations: [VNContoursObservation]) {
        var horizontalLines: [CGFloat] = []  // Strings
        var verticalLines: [CGFloat] = []    // Frets
        
        for observation in observations.prefix(50) {
            let path = observation.normalizedPath
            let bounds = path.boundingBox
            
            // Classify as horizontal (string) or vertical (fret) line
            let aspectRatio = bounds.width / bounds.height
            
            if aspectRatio > 3.0 && bounds.width > 0.15 {
                // Horizontal line (string)
                let yPos = 1 - bounds.midY  // Convert from Vision coordinates
                horizontalLines.append(yPos)
            } else if aspectRatio < 0.33 && bounds.height > 0.15 {
                // Vertical line (fret)
                let xPos = 1 - bounds.midX  // Convert from Vision coordinates
                verticalLines.append(xPos)
            }
        }
        
        // Filter and sort
        horizontalLines = Array(Set(horizontalLines)).sorted()
        verticalLines = Array(Set(verticalLines)).sorted()
        
        // Keep top 6 strings and 5 frets
        if horizontalLines.count >= 6 {
            horizontalLines = Array(horizontalLines.prefix(6))
        }
        if verticalLines.count >= 5 {
            verticalLines = Array(verticalLines.prefix(5))
        }
        
        detectionQueue.sync {
            if !horizontalLines.isEmpty {
                recentStringLines.append(horizontalLines)
                if recentStringLines.count > smoothingWindowSize {
                    recentStringLines.removeFirst()
                }
            }
            
            if !verticalLines.isEmpty {
                recentFretLines.append(verticalLines)
                if recentFretLines.count > smoothingWindowSize {
                    recentFretLines.removeFirst()
                }
            }
        }
        
        updateSmoothedLinesAndZone()
    }
    
    private func findGuitarNeckRectangle(from rectangles: [VNRectangleObservation]) -> VNRectangleObservation? {
        let candidates = rectangles.filter { rect in
            let width = rect.boundingBox.width
            let height = rect.boundingBox.height
            let area = width * height
            
            // Look for elongated rectangles
            let aspectRatio = height / width
            let isGoodAspect = (aspectRatio > 0.8 && aspectRatio < 3.5) || (aspectRatio > 0.3 && aspectRatio < 1.2)
            
            // Must be reasonably sized
            let isLargeEnough = area > 0.05 && (width > 0.15 || height > 0.15)
            
            return isGoodAspect && isLargeEnough
        }
        
        // Return the largest candidate
        return candidates.max {
            $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height
        }
    }
    
    private func convertToGuitarZone(_ rectangle: VNRectangleObservation) -> GuitarZone {
        let box = rectangle.boundingBox
        
        // Convert from Vision coordinates (bottom-left origin, mirrored)
        let leftX = 1 - box.maxX
        let rightX = 1 - box.minX
        let nutY = 1 - box.maxY
        let fret4Y = 1 - box.minY
        
        return GuitarZone(
            nutY: nutY,
            fret4Y: fret4Y,
            leftX: leftX,
            rightX: rightX
        )
    }
    
    private func addZoneToSmoothingBuffer(_ zone: GuitarZone) {
        detectionQueue.sync {
            recentZones.append(zone)
            if recentZones.count > smoothingWindowSize {
                recentZones.removeFirst()
            }
        }
        
        updateSmoothedLinesAndZone()
    }
    
    private func updateSmoothedLinesAndZone() {
        let smoothedZone = getSmoothedZone()
        let smoothedStrings = getSmoothedStrings()
        let smoothedFrets = getSmoothedFrets()
        
        DispatchQueue.main.async {
            self.detectedGuitarZone = smoothedZone
            self.detectedStringLines = smoothedStrings
            self.detectedFretLines = smoothedFrets
        }
    }
    
    private func getSmoothedZone() -> GuitarZone {
        return detectionQueue.sync {
            guard !recentZones.isEmpty else {
                return GuitarZone(nutY: 0.2, fret4Y: 0.8, leftX: 0.3, rightX: 0.7)
            }
            
            let avgNutY = recentZones.map { $0.nutY }.reduce(0, +) / CGFloat(recentZones.count)
            let avgFret4Y = recentZones.map { $0.fret4Y }.reduce(0, +) / CGFloat(recentZones.count)
            let avgLeftX = recentZones.map { $0.leftX }.reduce(0, +) / CGFloat(recentZones.count)
            let avgRightX = recentZones.map { $0.rightX }.reduce(0, +) / CGFloat(recentZones.count)
            
            return GuitarZone(
                nutY: avgNutY,
                fret4Y: avgFret4Y,
                leftX: avgLeftX,
                rightX: avgRightX
            )
        }
    }
    
    private func getSmoothedStrings() -> [CGFloat] {
        return detectionQueue.sync {
            guard !recentStringLines.isEmpty else { return [] }
            
            // Average each string position
            let maxCount = recentStringLines.map { $0.count }.max() ?? 0
            guard maxCount > 0 else { return [] }
            
            var averaged: [CGFloat] = []
            for i in 0..<min(maxCount, 6) {
                let values = recentStringLines.compactMap { $0.indices.contains(i) ? $0[i] : nil }
                if !values.isEmpty {
                    averaged.append(values.reduce(0, +) / CGFloat(values.count))
                }
            }
            
            return averaged.sorted()
        }
    }
    
    private func getSmoothedFrets() -> [CGFloat] {
        return detectionQueue.sync {
            guard !recentFretLines.isEmpty else { return [] }
            
            let maxCount = recentFretLines.map { $0.count }.max() ?? 0
            guard maxCount > 0 else { return [] }
            
            var averaged: [CGFloat] = []
            for i in 0..<min(maxCount, 5) {
                let values = recentFretLines.compactMap { $0.indices.contains(i) ? $0[i] : nil }
                if !values.isEmpty {
                    averaged.append(values.reduce(0, +) / CGFloat(values.count))
                }
            }
            
            return averaged.sorted()
        }
    }
    
    func startTracking() {
        isTracking = true
        recentZones = []
        recentFretLines = []
        recentStringLines = []
    }
    
    func stopTracking() {
        isTracking = false
        recentZones = []
        recentFretLines = []
        recentStringLines = []
        DispatchQueue.main.async {
            self.detectedGuitarZone = nil
            self.detectedFretLines = []
            self.detectedStringLines = []
        }
    }
}
