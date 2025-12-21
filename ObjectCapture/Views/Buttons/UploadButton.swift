//
//  UploadButton.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/21/25.
//

import SwiftUI
import ComposableArchitecture

struct UploadButton: View {
    let store: Store<AppFeature.State, AppFeature.Action>
    let isUploading: Bool
    let hasModel: Bool
    
    var body: some View {
        Button(action: {
            store.send(.uploadModel)
        }) {
            HStack(spacing: 8) {
                if isUploading {
                    ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "icloud.and.arrow.up")
                    .font(.system(size: 20, weight: .semibold))
            }
            
            Text(isUploading ? "Uploading..." : "Upload to Server")
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(hasModel && !isUploading ? Color.blue : Color.gray)
        )
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }
        .disabled(!hasModel || isUploading)
        .animation(.easeInOut(duration: 0.2), value: isUploading)
}
}

#Preview {
    VStack(spacing: 20) {
        UploadButton(
            store: Store(initialState: AppFeature.State()) {
                AppFeature()
            },
            isUploading: false,
            hasModel: true
        )
        
        UploadButton(
            store: Store(initialState: AppFeature.State()) {
                AppFeature()
            },
            isUploading: true,
            hasModel: true
        )
        
        UploadButton(
            store: Store(initialState: AppFeature.State()) {
                AppFeature()
            },
            isUploading: false,
            hasModel: false
        )
    }
    .padding()
}
