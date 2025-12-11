//
//  NextButton.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/11/25.
//

import SwiftUI
import RealityKit

struct NextButton: View {
    let action: () -> Void
    var session: ObjectCaptureSession
    var onShowSheet: () -> Void
    var onHideSheet: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            Text("Next")
                .padding(16.0)
                .font(.subheadline)
                .bold()
                .foregroundColor(.white)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .cornerRadius(15)
                .multilineTextAlignment(.center)
        })
    }
}
