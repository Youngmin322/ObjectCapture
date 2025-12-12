//
//  CaptureViewModel.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/4/25.
//

import SwiftUI
import RealityKit
import ComposableArchitecture

@MainActor
@Observable
class CaptureViewModel {
    // MARK: - Properties
    
    var appModel: Store<AppFeature.State, AppFeature.Action>!
    
    private let fileManager = FileManagerService()
    private var stateMonitorTask: Task<Void, Never>?
    
    
    // MARK: - Session Setup
    func setupSession() {
        let scansFolder = fileManager.getScansDirectory()
        fileManager.clearDirectory(scansFolder)
        
        var config = ObjectCaptureSession.Configuration()
        config.isOverCaptureEnabled = (appModel.captureMode == .object)
        
        session.start(imagesDirectory: scansFolder, configuration: config)
        
        startMonitoringCapture()
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
    
    private func startMonitoringCapture() {
        stateMonitorTask?.cancel()
        stateMonitorTask = Task {
            for await state in session.stateUpdates {
                updateCaptureProgress(state)
            }
        }
    }
    
    private func updateCaptureProgress(_ state: ObjectCaptureSession.CaptureState) {
        switch state {
        case .capturing:
            currentImageCount = session.numberOfShotsTaken
            totalImageCount = session.maximumNumberOfInputImages
        case .finishing:
            currentImageCount = session.numberOfShotsTaken
            totalImageCount = session.numberOfShotsTaken
        default:
            break
        }
    }
    
    // MARK: - Capture Control
    func startDetecting() {
        let success = session.startDetecting()
        print("Start detecting: \(success)")
    }
    
    func startCapturing() {
        session.startCapturing()
        isCapturing = true
        print("Capture started")
    }
    
    func finishCapturing() {
        session.finish()
        isCapturing = false
        showProcessButton = true
        print("Capture finished")
    }
    
    func toggleCaptureMode() {
        appModel.send(.toggleCaptureMode)
        reset()
    }
    
    // MARK: - Sheet Management
    func setShowOverlaySheets(to shown: Bool) {
        guard shown != showOverlaySheets else { return }
        
        if shown {
            showOverlaySheets = true
            session.pause()
            print("Session paused")
        } else {
            session.resume()
            showOverlaySheets = false
            print("Session resumed")
        }
    }
    
    // MARK: - 3D Reconstruction
    func startReconstruction() {
        processingMessage = "Preparing reconstruction..."
        
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
                print("Reconstruction failed: \(error)")
                processingMessage = "Reconstruction failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func handleReconstructionOutput(_ output: PhotogrammetrySession.Output, outputFile: URL) async {
        switch output {
        case .requestProgress(_, let fraction):
            processingMessage = "Processing... \(Int(fraction * 100))%"
            
        case .processingComplete:
            processingMessage = "Complete! (MyModel.usdz)"
            modelURL = outputFile
            showModelView = true
            print("Model created: \(outputFile)")
            
        case .requestError(_, let error):
            processingMessage = "Error: \(error.localizedDescription)"
            print("Reconstruction error: \(error)")
            
        default:
            break
        }
    }
    
    // MARK: - Reset
    func reset() {
        stateMonitorTask?.cancel()
        
        session = ObjectCaptureSession()
        
        showProcessButton = false
        processingMessage = ""
        isCapturing = false
        hasDetectionFailed = false
        showOverlaySheets = false
        setupSession()
    }
}
