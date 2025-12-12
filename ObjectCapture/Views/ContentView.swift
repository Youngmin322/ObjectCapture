//
//  ContentView.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/1/25.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @Environment(AppDataModel.self) var appModel
    @State private var viewModel: CaptureViewModel? = nil
    @State private var showOnboardingView = false
    
    var body: some View {
        ZStack {
            if let viewModel = viewModel {
                ObjectCaptureView(session: viewModel.session)
                    .blur(radius: viewModel.showOverlaySheets ? 45 : 0)
                
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
                
                if !viewModel.processingMessage.isEmpty {
                    ProcessingMessageView(message: viewModel.processingMessage)
                }
                
                VStack {
                    Spacer()
                    
                    HStack {
                        HStack {
                            Spacer()
                            
                            // Mode Toggle Button (Ready 상태에서만 표시)
                            if viewModel.session.state == .ready {
                                Button(action: {
                                    viewModel.toggleCaptureMode()
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: appModel.captureMode == .object ? "cube" : "circle.dashed")
                                            .font(.system(size: 20))
                                        Text(appModel.captureMode.displayName)
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(.ultraThinMaterial)
                                    .environment(\.colorScheme, .dark)
                                    .cornerRadius(15)
                                }
                                .padding(.trailing, 20)
                            }
                        }
                        .padding(.bottom, 120)
                    }
                    
                    HStack {
                        HStack { }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if case .capturing = viewModel.session.state {
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
                        }
                        
                        else {
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
                
                Color.clear
                    .sheet(isPresented: Binding(
                        get: { self.viewModel?.showModelView ?? false },
                        set: { self.viewModel?.showModelView = $0 }
                    )) {
                        if let url = viewModel.modelURL {
                            ARQuickLookView(modelFile: url) {
                                print("Viewer dismissed")
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
            }
        }
        .onAppear {
            if viewModel == nil {
                let vm = CaptureViewModel()
                vm.appModel = appModel
                vm.setupSession()
                viewModel = vm
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
}
