//
//  CaptureViewModel.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/4/25.
//

import SwiftUI
import RealityKit

@MainActor
@Observable
class CaptureViewModel {
    // MARK: - Properties
    var session = ObjectCaptureSession()
    var isCapturing = false
    var showProcessButton = false
    var hasDetectionFailed: Bool = false
    var processingMessage = ""
    var showModelView = false
    var modelURL: URL?
    
    private let fileManager = FileManagerService()
    
    // MARK: - Session Setup
    func setupSession() {
        let scansFolder = fileManager.getScansDirectory()
        fileManager.clearDirectory(scansFolder)
        
        var config = ObjectCaptureSession.Configuration()
        config.isOverCaptureEnabled = true
        
        session.start(imagesDirectory: scansFolder, configuration: config)
    }
    
    // MARK: - Capture Control
    func startDetecting() {
        _ = session.startDetecting()
    }
    
    func startCapturing() {
        session.startCapturing()
        isCapturing = true
        print("촬영 시작")
    }
    
    func finishCapturing() {
        session.finish()
        isCapturing = false
        showProcessButton = true
        print("촬영 종료")
    }
    
    // MARK: - 3D Reconstruction
    func startReconstruction() {
        processingMessage = "변환 준비 중..."
        
        let inputFolder = fileManager.getScansDirectory()
        let outputFile = fileManager.getModelOutputPath()
        
        Task {
            do {
                let photoSession = try PhotogrammetrySession(input: inputFolder)
                try photoSession.process(requests: [.modelFile(url: outputFile)])
                
                for try await output in photoSession.outputs {
                    await handleReconstructionOutput(output, outputFile: outputFile)
                }
            } catch {
                print("3D 변환 실패: \(error)")
                processingMessage = "변환 실패: \(error.localizedDescription)"
            }
        }
    }
    
    private func handleReconstructionOutput(_ output: PhotogrammetrySession.Output, outputFile: URL) async {
        switch output {
        case .requestProgress(_, let fraction):
            processingMessage = "변환 중... \(Int(fraction * 100))%"
            
        case .processingComplete:
            processingMessage = "완성 (MyModel.usdz)"
            modelURL = outputFile
            showModelView = true
            print("성공 파일 위치: \(outputFile)")
            
        case .requestError(_, let error):
            processingMessage = "오류 발생: \(error)"
            print("Error: \(error)")
            
        default:
            break
        }
    }
    
    // MARK: - Reset
    func reset() {
        showProcessButton = false
        processingMessage = ""
        isCapturing = false
        setupSession()
    }
}
