//
//  CaptureProgressView.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/11/25.
//

import SwiftUI
import RealityKit

// MARK: - Capture Progress Component
struct CaptureProgressView: View {
    var session: ObjectCaptureSession
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "photo")
                .foregroundColor(.white)
            
            Text("\(session.numberOfShotsTaken)/\(session.maximumNumberOfInputImages)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
    }
}
