//
//  FeedbackCard.swift
//  guitarmax
//
//  Created by albert ho on 12/19/25.
//

import SwiftUI

struct FeedbackCard: View {
    let icon: String
    let title: String
    let status: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(status)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(15)
    }
}
