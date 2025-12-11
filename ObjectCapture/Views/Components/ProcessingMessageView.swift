//
//  ProcessingMessageView.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/11/25.
//

import SwiftUI

// MARK: - Processing Message Component
struct ProcessingMessageView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.headline)
            .padding()
            .background(.black.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.bottom, 20)
    }
}
