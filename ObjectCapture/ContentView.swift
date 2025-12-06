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
                Spacer()
                
                // 처리 상태 메시지
                if !viewModel.processingMessage.isEmpty {
                    ProcessingMessageView(message: viewModel.processingMessage)
                }

                // 캡처 버튼
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


#Preview("ContentView - 기본") {
    // 프리뷰용 더미 배경 뷰로 ObjectCaptureView 대체
    struct DummyCaptureBackground: View {
        var body: some View {
            ZStack {
                Color.black.opacity(0.9)
                Text("Object Capture Preview")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.headline)
            }
            .ignoresSafeArea()
        }
    }

    // 프리뷰 전용 컨테이너로 ViewModel을 설정
    struct ContentViewPreviewContainer: View {
        @State private var viewModel = CaptureViewModel()

        var body: some View {
            ZStack {
                // 실제 캡처 뷰 대신 더미 배경
                DummyCaptureBackground()

                VStack {
                    Spacer()

                    // 메시지 표시 예시
                    if !viewModel.processingMessage.isEmpty {
                        ProcessingMessageView(message: viewModel.processingMessage)
                    }

                    // 캡처 버튼 (실제 세션을 사용하지만 프리뷰에서는 액션을 로그로만 처리)
                    CaptureButton(
                        session: viewModel.session,
                        hasDetectionFailed: $viewModel.hasDetectionFailed,
                        showProcessButton: viewModel.showProcessButton,
                        onContinue: { print("Continue tapped (Preview)") },
                        onStartCapture: { print("Start Capture tapped (Preview)") },
                        onFinishCapture: { print("Finish Capture tapped (Preview)") },
                        onProcess: { print("Process tapped (Preview)") }
                    )
                }
            }
            // 프리뷰에서는 실제 세션 시작을 막고, UI 확인용 더미 상태를 세팅
            .task {
                // 메시지/버튼 노출 상태를 보기 위한 더미 값
                viewModel.processingMessage = "변환 중... 35%"
                viewModel.showProcessButton = false
            }
        }
    }

    return ContentViewPreviewContainer()
        // AppDataModel 환경 주입 (필수)
        .environment(AppDataModel())
}
