//
//  GuitarChord.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import Foundation

enum GuitarChord: String, CaseIterable {
    case C = "C"
    case D = "D"
    case E = "E"
    case G = "G"
    case A = "A"
    case Am = "Am"
    case Em = "Em"
    case Dm = "Dm"
    
    var fingerPositions: [FingerPosition] {
        // String numbering: 1 = high E (thinnest), 6 = low E (thickest)
        // Fret: -1 = muted (X), 0 = open (O), 1+ = fret number
        // Finger: 0 = none, 1 = index, 2 = middle, 3 = ring, 4 = pinky
        
        switch self {
        case .C:
            // x-3-2-0-1-0
            return [
                FingerPosition(string: 6, fret: -1, finger: 0),
                FingerPosition(string: 5, fret: 3, finger: 3), // ring
                FingerPosition(string: 4, fret: 2, finger: 2), // middle
                FingerPosition(string: 3, fret: 0, finger: 0),
                FingerPosition(string: 2, fret: 1, finger: 1), // index
                FingerPosition(string: 1, fret: 0, finger: 0)
            ]
            
        case .G:
            // 3-2-0-0-0-3 (standard 3-finger G)
            return [
                FingerPosition(string: 6, fret: 3, finger: 3), // ring
                FingerPosition(string: 5, fret: 2, finger: 2), // middle
                FingerPosition(string: 4, fret: 0, finger: 0),
                FingerPosition(string: 3, fret: 0, finger: 0),
                FingerPosition(string: 2, fret: 0, finger: 0),
                FingerPosition(string: 1, fret: 3, finger: 4)  // pinky
            ]
            
        case .D:
            // x-x-0-2-3-2
            return [
                FingerPosition(string: 6, fret: -1, finger: 0),
                FingerPosition(string: 5, fret: -1, finger: 0),
                FingerPosition(string: 4, fret: 0, finger: 0),
                FingerPosition(string: 3, fret: 2, finger: 1), // index
                FingerPosition(string: 2, fret: 3, finger: 3), // ring
                FingerPosition(string: 1, fret: 2, finger: 2)  // middle
            ]
            
        case .Em:
            // 0-2-2-0-0-0
            return [
                FingerPosition(string: 6, fret: 0, finger: 0),
                FingerPosition(string: 5, fret: 2, finger: 2), // middle
                FingerPosition(string: 4, fret: 2, finger: 3), // ring
                FingerPosition(string: 3, fret: 0, finger: 0),
                FingerPosition(string: 2, fret: 0, finger: 0),
                FingerPosition(string: 1, fret: 0, finger: 0)
            ]
            
        case .Am:
            // x-0-2-2-1-0 (corrected fingering)
            return [
                FingerPosition(string: 6, fret: -1, finger: 0),
                FingerPosition(string: 5, fret: 0, finger: 0),
                FingerPosition(string: 4, fret: 2, finger: 2), // middle
                FingerPosition(string: 3, fret: 2, finger: 3), // ring
                FingerPosition(string: 2, fret: 1, finger: 1), // index
                FingerPosition(string: 1, fret: 0, finger: 0)
            ]
            
        case .E:
            // 0-2-2-1-0-0
            return [
                FingerPosition(string: 6, fret: 0, finger: 0),
                FingerPosition(string: 5, fret: 2, finger: 2), // middle
                FingerPosition(string: 4, fret: 2, finger: 3), // ring
                FingerPosition(string: 3, fret: 1, finger: 1), // index
                FingerPosition(string: 2, fret: 0, finger: 0),
                FingerPosition(string: 1, fret: 0, finger: 0)
            ]
            
        case .A:
            // x-0-2-2-2-0
            return [
                FingerPosition(string: 6, fret: -1, finger: 0),
                FingerPosition(string: 5, fret: 0, finger: 0),
                FingerPosition(string: 4, fret: 2, finger: 1), // index
                FingerPosition(string: 3, fret: 2, finger: 2), // middle
                FingerPosition(string: 2, fret: 2, finger: 3), // ring
                FingerPosition(string: 1, fret: 0, finger: 0)
            ]
            
        case .Dm:
            // x-x-0-2-3-1 (fixed)
            return [
                FingerPosition(string: 6, fret: -1, finger: 0),
                FingerPosition(string: 5, fret: -1, finger: 0),
                FingerPosition(string: 4, fret: 0, finger: 0),
                FingerPosition(string: 3, fret: 2, finger: 2), // middle
                FingerPosition(string: 2, fret: 3, finger: 3), // ring
                FingerPosition(string: 1, fret: 1, finger: 1)  // index
            ]
        }
    }
}

struct FingerPosition {
    let string: Int   // 1-6, where 1 is high E, 6 is low E
    let fret: Int     // -1 = muted, 0 = open, 1+ = fret number
    let finger: Int   // 0 = none, 1 = index, 2 = middle, 3 = ring, 4 = pinky
}
