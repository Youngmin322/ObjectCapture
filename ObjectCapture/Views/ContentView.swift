//
//  ContentView.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/1/25.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var viewModel = CaptureViewModel()

    var body: some View {
        ZStack {
            ObjectCaptureView(session: viewModel.session)
            
            VStack {
                HStack {
                    if case .detecting = viewModel.session.state {
                        CaptureCancelButton {
                            viewModel.reset()
                        }
                    } else if case .capturing = viewModel.session.state {
                        CaptureCancelButton {
                            viewModel.reset()
                        }
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
            
            VStack {
                Spacer()
                
                // 처리 상태 메시지
                if !viewModel.processingMessage.isEmpty {
                    ProcessingMessageView(message: viewModel.processingMessage)
                }
                
                // 캡처 버튼
                if case .capturing = viewModel.session.state {
                    
                } else {
                    CaptureButton(
                        session: viewModel.session,
                        hasDetectionFailed: $viewModel.hasDetectionFailed,
                        showProcessButton: viewModel.showProcessButton,
                        onContinue: { viewModel.startDetecting() },
                        onStartCapture: { viewModel.startCapturing() },
                        onFinishCapture: { viewModel.finishCapturing() },
                        onProcess: { viewModel.startReconstruction() }
                    )
                }
            }
        }
        .onAppear {
            viewModel.setupSession()
        }
        .sheet(isPresented: $viewModel.showModelView) {
            if let url = viewModel.modelURL {
                ARQuickLookView(modelFile: url) {
                    print("뷰어 닫힘")
                    viewModel.reset()
                }
            }
        }
    }
}

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

private struct CaptureCancelButton: View {
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
