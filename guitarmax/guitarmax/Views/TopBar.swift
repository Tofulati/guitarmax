//
//  TopBar.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import SwiftUI

struct TopBar: View {
    @Binding var selectedChord: GuitarChord
    @Binding var isLessonActive: Bool
    
    var body: some View {
        HStack {
            Text("Learn Guitar")
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
            } else {
                Text(selectedChord.rawValue)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(15)
    }
}
