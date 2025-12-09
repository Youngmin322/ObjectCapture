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
                
                HStack {
                    HStack {
                        if case .capturing = viewModel.session.state {
                            CaptureProgressView(session: viewModel.session)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    
                    Spacer()
                        .frame(width: 200)
                    
                    HStack { }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.bottom, 80)
            }
            
            // 처리 상태 메시지
            if !viewModel.processingMessage.isEmpty {
                ProcessingMessageView(message: viewModel.processingMessage)
            }
            
            VStack {
                Spacer()
                
                HStack {
                    HStack { }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if case .capturing = viewModel.session.state {
                        
                    } else {
                        CaptureButton(
                            hasDetectionFailed: $viewModel.hasDetectionFailed,
                            session: viewModel.session,
                            showProcessButton: viewModel.showProcessButton,
                            onContinue: { viewModel.startDetecting() },
                            onStartCapture: { viewModel.startCapturing() },
                            onFinishCapture: { viewModel.finishCapturing() },
                            onProcess: { viewModel.startReconstruction() }
                        )
                        .frame(width: 200)
                    }
                    
                    HStack { }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.bottom, 40)
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

//#Preview {
//    CaptureProgressView(session: numberOfShotsTaken)
//}
