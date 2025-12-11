//
//  CaptureCancelButton.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/11/25.
//

import SwiftUI

struct CaptureCancelButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            Text("Cancel")
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
