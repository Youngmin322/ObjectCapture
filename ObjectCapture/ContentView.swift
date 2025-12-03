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
    @State private var showProcessButton = false // 촬영 끝나면 버튼 보여주기용
    @State private var processingMessage = "" // 진행 상황 표시
    @State private var showModelView = false
    @State private var modelURL: URL?

    var body: some View {
        ZStack {
            ObjectCaptureView(session: session)
            
            VStack {
                Spacer()
                
                // 진행 상황 메시지 (처리 중일 때 뜸)
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
                    
                } else {
                    Button(action: {
                        if isCapturing {
                            session.finish()
                            isCapturing = false
                            showProcessButton = true
                            print("촬영 종료")
                        } else {
                            session.startCapturing()
                            isCapturing = true
                            print("촬영 시작")
                        }
                    }) {
                        Text(isCapturing ? "촬영 완료 (Finish)" : "촬영 시작 (Start)")
                            .font(.title3).bold()
                            .padding().frame(maxWidth: .infinity)
                            .background(isCapturing ? Color.red : Color.blue)
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
                    setupSession() // 세션 다시 준비
                }
            }
        }
    }
    
    // 세션 초기화 및 폴더 설정
    func setupSession() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let scansFolder = documentsPath.appendingPathComponent("Scans")
        
        // 기존 폴더가 있으면 지우고 다시 시작
        if FileManager.default.fileExists(atPath: scansFolder.path) {
            try? FileManager.default.removeItem(at: scansFolder)
        }
        try? FileManager.default.createDirectory(at: scansFolder, withIntermediateDirectories: true)
        
        var config = ObjectCaptureSession.Configuration()
        config.isOverCaptureEnabled = true
        
        session.start(imagesDirectory: scansFolder, configuration: config)
    }
    
    // 3D 모델 생성 함수
    func startReconstruction() {
        processingMessage = "변환 준비 중..."
        
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let inputFolder = documentsPath.appendingPathComponent("Scans")
        let outputFile = documentsPath.appendingPathComponent("MyModel.usdz")
        
        Task {
            do {
                // 세션 생성
                let photoSession = try PhotogrammetrySession(input: inputFolder)
                
                // 처리 시작 요청
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
                // 여기서 모든 에러를 잡습니다.
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
    var endCaptureCallback: () -> Void // 닫을 때 실행할 함수
    
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

            // 보여줄 파일 개수 (1개)
            func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
                return 1
            }

            // 실제 파일 위치 알려주기
            func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
                return parent.modelFile as QLPreviewItem
            }
            
            // 뷰어가 닫힐 때 호출
            func previewControllerDidDismiss(_ controller: QLPreviewController) {
                parent.endCaptureCallback()
            }
        }
    }
