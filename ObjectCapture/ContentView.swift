//
//  ContentView.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/1/25.
//

import SwiftUI
import RealityKit
import QuickLook

struct ContentView: View {
    @State private var session = ObjectCaptureSession()
    @State private var isCapturing = false
    @State private var showProcessButton = false
    @State private var processingMessage = ""
    @State private var showModelView = false
    @State private var modelURL: URL?

    var body: some View {
        ZStack {
            ObjectCaptureView(session: session)
            
            VStack {
                Spacer()
                
                if !processingMessage.isEmpty {
                    Text(processingMessage)
                        .font(.headline)
                        .padding()
                        .background(.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                }

                // 버튼 영역
                if showProcessButton {
                    Button(action: {
                        startReconstruction()
                    }) {
                        Text("3D 모델 만들기")
                            .font(.title3).bold()
                            .padding().frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                    
                } else if case .ready = session.state {
                    // Continue 버튼
                    Button(action: {
                        session.startDetecting()
                    }) {
                        Text("Continue")
                            .font(.title3).bold() 
                            .padding().frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                    
                } else if case .detecting = session.state {
                    // 감지 완료 후 촬영 시작 버튼
                    Button(action: {
                        session.startCapturing()
                        isCapturing = true
                        print("촬영 시작")
                    }) {
                        Text("촬영 시작")
                            .font(.title3).bold()
                            .padding().frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                    
                } else if case .capturing = session.state {
                    // 촬영 중//
                    Button(action: {
                        session.finish()
                        isCapturing = false
                        showProcessButton = true
                        print("촬영 종료")
                    }) {
                        Text("촬영 완료")
                            .font(.title3).bold()
                            .padding().frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            setupSession()
        }
        .sheet(isPresented: $showModelView) {
            if let url = modelURL {
                ARQuickLookView(modelFile: url) {
                    print("뷰어 닫힘")
                    showProcessButton = false
                    processingMessage = ""
                    isCapturing = false
                    setupSession()
                }
            }
        }
    }
    
    func setupSession() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let scansFolder = documentsPath.appendingPathComponent("Scans")
        
        if FileManager.default.fileExists(atPath: scansFolder.path) {
            try? FileManager.default.removeItem(at: scansFolder)
        }
        try? FileManager.default.createDirectory(at: scansFolder, withIntermediateDirectories: true)
        
        var config = ObjectCaptureSession.Configuration()
        config.isOverCaptureEnabled = true
        
        session.start(imagesDirectory: scansFolder, configuration: config)
    }
    
    func startReconstruction() {
        processingMessage = "변환 준비 중..."
        
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let inputFolder = documentsPath.appendingPathComponent("Scans")
        let outputFile = documentsPath.appendingPathComponent("MyModel.usdz")
        
        Task {
            do {
                let photoSession = try PhotogrammetrySession(input: inputFolder)
                try photoSession.process(requests: [.modelFile(url: outputFile)])
                
                for try await output in photoSession.outputs {
                    switch output {
                    case .requestProgress(_, let fraction):
                        await MainActor.run {
                            processingMessage = "변환 중... \(Int(fraction * 100))%"
                        }
                        
                    case .processingComplete:
                        await MainActor.run {
                            processingMessage = "완성 (MyModel.usdz)"
                            modelURL = outputFile
                            showModelView = true
                        }
                        print("성공 파일 위치: \(outputFile)")
                        
                    case .requestError(_, let error):
                        await MainActor.run {
                            processingMessage = "오류 발생: \(error)"
                        }
                        print("Error: \(error)")
                        
                    default:
                        break
                    }
                }
            } catch {
                print("3D 변환 실패: \(error)")
                await MainActor.run {
                    processingMessage = "변환 실패: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ARQuickLookView: UIViewControllerRepresentable {
    var modelFile: URL
    var endCaptureCallback: () -> Void
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let parent: ARQuickLookView

        init(parent: ARQuickLookView) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.modelFile as QLPreviewItem
        }
        
        func previewControllerDidDismiss(_ controller: QLPreviewController) {
            parent.endCaptureCallback()
        }
    }
}
