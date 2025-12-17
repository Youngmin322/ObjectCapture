//
//  CaptureButton.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/11/25.
//

import SwiftUI
import RealityKit
import ComposableArchitecture

struct CaptureButton: View {
    @Environment(Store<AppFeature.State, AppFeature.Action>.self) var store
    
    var session: ObjectCaptureSession
    let showProcessButton: Bool
    let onContinue: () -> Void
    let onStartCapture: () -> Void
    let onFinishCapture: () -> Void
    let onProcess: () -> Void
    
    var body: some View {
        Button(
            action: {
                performAction()
            },
            label: {
                if let label = buttonLabel {
                    Text(label)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 20)
                        .background(.blue)
                        .clipShape(Capsule())
                        .glassEffect()
                }
            })
    }
    
    private var buttonLabel: String? {
        switch session.state {
        case .ready:
            return store.captureMode == .object ? "Continue" : "Start Capture"
        case .detecting:
            return "Start Capture"
        case .capturing:
            return nil
        default:
            return nil
        }
    }
    
    private func performAction() {
        switch session.state {
        case .ready:
            if store.captureMode == .object {
                onContinue()
            } else {
                onStartCapture()
            }
        case .detecting:
            onStartCapture()
        default:
            break
        }
    }
}
