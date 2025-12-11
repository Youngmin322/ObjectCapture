//
//  CaptureButton.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/11/25.
//

import SwiftUI
import RealityKit

struct CaptureButton: View {
    @Environment(AppDataModel.self) var appModel
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
                }
            })
    }
    
    private var buttonLabel: String? {
        switch session.state {
        case .ready:
            return appModel.captureMode == .object ? "Continue" : "Start Capture"
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
            if appModel.captureMode == .object {
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
