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
    @State private var showOnboardingView = false
    
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
                    
                    if case .capturing = viewModel.session.state {
                        NextButton(
                            action: {
                                print("Next button clicked!")
                                showOnboardingView = true
                            },
                            session: viewModel.session,
                            onShowSheet: { viewModel.setShowOverlaySheets(to: true) },
                            onHideSheet: { viewModel.setShowOverlaySheets(to: false) }
                        )
                    }
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
                        // 촬영 중일 때 오른쪽 하단에 버튼 표시
                        HStack {
                            Spacer()
                            CaptureButton(
                                session: viewModel.session,
                                showProcessButton: viewModel.showProcessButton,
                                onContinue: { viewModel.startDetecting() },
                                onStartCapture: { viewModel.startCapturing() },
                                onFinishCapture: { viewModel.finishCapturing() },
                                onProcess: { viewModel.startReconstruction() }
                            )
                        }
                    } else {
                        CaptureButton(
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
        .sheet(isPresented: $showOnboardingView) {
            OnboardingReviewView(
                session: viewModel.session,
                showOnboardingView: $showOnboardingView
            )
        }
        .onChange(of: showOnboardingView) { oldValue, newValue in
            if newValue {
                viewModel.setShowOverlaySheets(to: true)
            } else {
                viewModel.setShowOverlaySheets(to: false)
            }
        }
        .task {
            // 스캔 패스 완료 시 자동으로 시트 띄우기
            for await userCompletedScanPass in viewModel.session.userCompletedScanPassUpdates where userCompletedScanPass {
                print("Scan pass completed! Showing review...")
                showOnboardingView = true
            }
        }
    }
}
