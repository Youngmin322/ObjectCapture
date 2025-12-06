//
//  CaptureButtonView.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/4/25.
//

import SwiftUI
import RealityKit

struct CaptureButton: View {
    @Environment(AppDataModel.self) var appModel
    var session: ObjectCaptureSession
    @Binding var hasDetectionFailed: Bool
    
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
                Text(buttonLabel)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 20)
                    .background(.blue)
                    .clipShape(Capsule())
            })
    }

    private var buttonLabel: String {
        if session.state == .ready {
            switch appModel.captureMode {
                case .object:
                    return "Continue"
                case .area:
                    return "Start Capture"
            }
        } else {
            if !appModel.isObjectFlipped {
                return "Start Capture"
            } else {
                return "Continue"
            }
        }
    }

    private func performAction() {
        if session.state == .ready {
            switch appModel.captureMode {
            case .object:
                hasDetectionFailed = !(session.startDetecting())
            case .area:
                session.startCapturing()
            }
        } else if case .detecting = session.state {
            session.startCapturing()
        }
    }
}

// MARK: - Action Button Component
struct ActionButton: View {
    let title: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .background(.blue)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 50)
    }
}
