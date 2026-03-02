//
//  ContentView.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/1/25.
//

import SwiftUI
import RealityKit
import ComposableArchitecture

struct ContentView: View {
    @Environment(Store<AppFeature.State, AppFeature.Action>.self) var store
    @State private var viewModel: CaptureViewModel? = nil
    @State private var showOnboardingView = false
    @State private var isSessionReady = false
    
    var body: some View {
        ZStack {
            if let viewModel = viewModel, isSessionReady {
                // 세션 상태에 따라 다른 화면 표시
                if case .completed = viewModel.session.state {
                    // 촬영 완료 화면
                    completedView(viewModel: viewModel)
                } else {
                    // 촬영 중 화면
                    captureView(viewModel: viewModel)
                }
                
                // 공통 UI 요소
                if !viewModel.processingMessage.isEmpty {
                    ProcessingMessageView(message: viewModel.processingMessage)
                }
                
                // Sheets
                Color.clear
                    .sheet(isPresented: Binding(
                        get: { self.viewModel?.showModelView ?? false },
                        set: { self.viewModel?.showModelView = $0 }
                    )) {
                        if let url = viewModel.modelURL {
                            modelViewSheet(url: url, viewModel: viewModel)
                        }
                    }
                    .sheet(isPresented: $showOnboardingView) {
                        OnboardingReviewView(
                            session: viewModel.session,
                            showOnboardingView: $showOnboardingView,
                            onFinish: {
                                viewModel.finishCapturing()
                            }
                        )
                    }
                    .onChange(of: showOnboardingView) { oldValue, newValue in
                        if newValue {
                            viewModel.setShowOverlaySheets(to: true)
                        } else {
                            if case .capturing = viewModel.session.state {
                                viewModel.setShowOverlaySheets(to: false)
                            } else if case .detecting = viewModel.session.state {
                                viewModel.setShowOverlaySheets(to: false)
                            }
                        }
                    }
            } else {
                // 로딩 화면
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text("Initializing Camera Session...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                let vm = CaptureViewModel()
                vm.appModel = store
                viewModel = vm
                
                Task {
                    vm.setupSession()
                    
                    for await state in vm.session.stateUpdates {
                        print("Waiting for session ready, current state: \(state)")
                        if case .ready = state {
                            print("Session is ready")
                            isSessionReady = true
                            break
                        }
                        if case .detecting = state {
                            print("Session is detecting")
                            isSessionReady = true
                            break
                        }
                        if case .capturing = state {
                            print("Session is capturing")
                            isSessionReady = true
                            break
                        }
                    }
                }
            }
        }
        .task {
            guard let viewModel = viewModel else { return }
            for await userCompletedScanPass in viewModel.session.userCompletedScanPassUpdates where userCompletedScanPass {
                print("Scan pass completed! Showing review...")
                showOnboardingView = true
            }
        }
    }
    
    // MARK: - 촬영 완료 화면
    @ViewBuilder
    private func completedView(viewModel: CaptureViewModel) -> some View {
        VStack(spacing: 30) {
            Text("촬영 완료!")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
            
            Text("\(viewModel.session.numberOfShotsTaken)장의 사진이 캡처되었습니다")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 16) {
                Button(action: {
                    viewModel.startReconstruction()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "cube.fill")
                        Text("3D 모델 생성")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    isSessionReady = false
                    viewModel.reset()
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        isSessionReady = true
                    }
                }) {
                    Text("새로 시작")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - 촬영 중 화면
    @ViewBuilder
    private func captureView(viewModel: CaptureViewModel) -> some View {
        ObjectCaptureView(session: viewModel.session)
            .blur(radius: viewModel.showOverlaySheets ? 45 : 0)
        
        VStack {
            HStack {
                if case .detecting = viewModel.session.state {
                    CaptureCancelButton { viewModel.reset() }
                } else if case .capturing = viewModel.session.state {
                    CaptureCancelButton { viewModel.reset() }
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
                // 왼쪽 - 촬영 진행률 (캡처 중일 때만)
                HStack {
                    if case .capturing = viewModel.session.state {
                        CaptureProgressView(session: viewModel.session)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                // 중앙 - 메인 캡처 버튼 (Continue / Start / Finish 등 상태 제어)
                CaptureButton(
                    session: viewModel.session,
                    showProcessButton: viewModel.showProcessButton,
                    onContinue: { viewModel.startDetecting() },
                    onStartCapture: { viewModel.startCapturing() },
                    onFinishCapture: { viewModel.finishCapturing() },
                    onProcess: { viewModel.startReconstruction() }
                )
                .frame(width: 200)  

                HStack {
                    CaptureControlButton(
                        store: store,
                        session: viewModel.session
                    )
                    .onTapGesture {
                        // 1. 세션 연결을 끊기 위해 뷰를 먼저 숨김
                        isSessionReady = false
                        
                        // 2. TCA를 통해 세션 리셋 및 모드 전환
                        store.send(.toggleCaptureMode)
                        
                        // 하드웨어 정리 시간
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
                            
                            // 4. AppFeature에서 새 세션이 생성되었을 것이므로 뷰모델 세션 업데이트
                            // (TCA Dependency 등을 통해 세션이 주입되는 구조라면 해당 세션 참조)
                            
                            isSessionReady = true
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - 모델 뷰어 시트
    @ViewBuilder
    private func modelViewSheet(url: URL, viewModel: CaptureViewModel) -> some View {
        VStack(spacing: 0) {
            if !store.uploadMessage.isEmpty {
                HStack {
                    Image(systemName: store.uploadMessage.contains("✓") ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(store.uploadMessage.contains("✓") ? .green : .red)
                    
                    Text(store.uploadMessage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(store.uploadMessage.contains("✓") ? .green : .red)
                    
                    Spacer()
                }
                .padding()
                .background(
                    store.uploadMessage.contains("✓")
                        ? Color.green.opacity(0.1)
                        : Color.red.opacity(0.1)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(duration: 0.3), value: store.uploadMessage)
            }
            
            ARQuickLookView(modelFile: url) {
                print("Viewer dismissed")
                // reset()을 호출하지 않고 그냥 뷰만 닫음
                viewModel.showModelView = false
            }
            
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.showModelView = false
                        viewModel.reset()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Close")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray)
                        )
                    }
                    
                    UploadButton(
                        store: store,
                        isUploading: store.isUploading,
                        hasModel: store.modelURL != nil
                    )
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
