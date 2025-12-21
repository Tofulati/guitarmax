//
//  GuitarChord.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import Foundation

enum GuitarChord: String, CaseIterable {
    case C, D, E, G, A, Am, Em, Dm
    
    var fingerPositions: [FingerPosition] {
        switch self {

        case .C:
            // x-3-2-0-1-0
            return [
                .init(string: 6, fret: -1, finger: 0),
                .init(string: 5, fret: 3, finger: 3),
                .init(string: 4, fret: 2, finger: 2),
                .init(string: 3, fret: 0, finger: 0),
                .init(string: 2, fret: 1, finger: 1),
                .init(string: 1, fret: 0, finger: 0)
            ]

        case .G:
            // 3-2-0-0-0-3
            return [
                .init(string: 6, fret: 3, finger: 3),
                .init(string: 5, fret: 2, finger: 2),
                .init(string: 4, fret: 0, finger: 0),
                .init(string: 3, fret: 0, finger: 0),
                .init(string: 2, fret: 0, finger: 0),
                .init(string: 1, fret: 3, finger: 4)
            ]

        case .D:
            // x-x-0-2-3-2
            return [
                .init(string: 6, fret: -1, finger: 0),
                .init(string: 5, fret: -1, finger: 0),
                .init(string: 4, fret: 0, finger: 0),
                .init(string: 3, fret: 2, finger: 1),
                .init(string: 2, fret: 3, finger: 3),
                .init(string: 1, fret: 2, finger: 2)
            ]

        case .Em:
            // 0-2-2-0-0-0
            return [
                .init(string: 6, fret: 0, finger: 0),
                .init(string: 5, fret: 2, finger: 2),
                .init(string: 4, fret: 2, finger: 3),
                .init(string: 3, fret: 0, finger: 0),
                .init(string: 2, fret: 0, finger: 0),
                .init(string: 1, fret: 0, finger: 0)
            ]

        case .Am:
            // x-0-2-2-1-0
            return [
                .init(string: 6, fret: -1, finger: 0),
                .init(string: 5, fret: 0, finger: 0),
                .init(string: 4, fret: 2, finger: 2),
                .init(string: 3, fret: 2, finger: 3),
                .init(string: 2, fret: 1, finger: 1),
                .init(string: 1, fret: 0, finger: 0)
            ]

        case .E:
            // 0-2-2-1-0-0
            return [
                .init(string: 6, fret: 0, finger: 0),
                .init(string: 5, fret: 2, finger: 2),
                .init(string: 4, fret: 2, finger: 3),
                .init(string: 3, fret: 1, finger: 1),
                .init(string: 2, fret: 0, finger: 0),
                .init(string: 1, fret: 0, finger: 0)
            ]

        case .A:
            // x-0-2-2-2-0
            return [
                .init(string: 6, fret: -1, finger: 0),
                .init(string: 5, fret: 0, finger: 0),
                .init(string: 4, fret: 2, finger: 1),
                .init(string: 3, fret: 2, finger: 2),
                .init(string: 2, fret: 2, finger: 3),
                .init(string: 1, fret: 0, finger: 0)
            ]

        case .Dm:
            // x-x-0-2-3-1
            return [
                .init(string: 6, fret: -1, finger: 0),
                .init(string: 5, fret: -1, finger: 0),
                .init(string: 4, fret: 0, finger: 0),
                .init(string: 3, fret: 2, finger: 2),
                .init(string: 2, fret: 3, finger: 3),
                .init(string: 1, fret: 1, finger: 1)
            ]
        }
    }
}

struct FingerPosition {
    let string: Int   // 1 = high e, 6 = low E
    let fret: Int     // -1 muted, 0 open, 1+ fretted
    let finger: Int   // 1 index, 2 middle, 3 ring, 4 pinky
}
