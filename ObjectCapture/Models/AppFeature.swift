//
//  AppFeature.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/4/25.
//

import SwiftUI
import RealityKit
import ComposableArchitecture

@Reducer
struct AppFeature {
    // MARK: State
    @ObservableState
    struct State: Equatable {
        var captureMode: CaptureMode = .object
        var currentOrbit: Orbit = .orbit1
        var isObjectFlipped: Bool = false
        var isObjectFlippable: Bool = true
        var hasIndicatedObjectCannotBeFlipped: Bool = false
        var hasIndicatedFlipObjectAnyway: Bool = false
        var tutorialPlayedOnce: Bool = false
        
        var isCapturing = false
        var showProcessButton = false
        var hasDetectionFailed = false
        var processingMessage = ""
        var modelURL: URL?
        var showOverlaySheets = false
        var showModelView = false
        var currentImageCount = 0
        var totalImageCount = 0
        
        var numberOfShotsTaken = 0
        var maximumNumberOfInputImages = 100
        
        var isUploading = false // 업로드 여부
        var uploadMessage = "" // 화면에 보여줄 결과 메시지
        
        // MARK: Nested Types
        enum CaptureMode: Equatable {
            case object
            case area
            
            var displayName: String {
                switch self {
                case .object: return "Object"
                case .area: return "Area"
                }
            }
            
            var nextMode: CaptureMode {
                switch self {
                case .object: return .area
                case .area: return .object
                }
            }
        }
        
        enum Orbit: Int, CaseIterable, Identifiable {
            case orbit1 = 1
            case orbit2 = 2
            case orbit3 = 3
            
            var id: Int { rawValue }
            
            var displayName: String {
                switch self {
                case .orbit1: return "First Pass"
                case .orbit2: return "Second Pass"
                case .orbit3: return "Third Pass"
                }
            }
            
            func next() -> Orbit {
                switch self {
                case .orbit1: return .orbit2
                case .orbit2: return .orbit3
                case .orbit3: return .orbit3
                }
            }
        }
    }
    
    // MARK: Action
    enum Action: Equatable {
        case onAppear
        
        case toggleCaptureMode
        case resetState
        case setCurrentOrbit(State.Orbit)
        case flipObject
        
        case setupSession
        case startDetecting
        case startCapturing
        case finishCapturing
        case setShowOverlaySheets(Bool)
        case startReconstruction
        case reset
        
        // 세션 업데이트
        case sessionStateChanged
        case captureProgressUpdated(current: Int, total: Int)
        case reconstructionProgressUpdated(Float)
        case reconstructionCompleted(URL)
        case reconstructionFailed(String)
        
        // 세션 모니터링
        case monitorSessionState
        case sessionMaxImagesUpdated(Int)
        
        // 업로드 액션
        case uploadModel
        case uploadStarted
        case uploadCompleted(String)
        case uploadFailed(String)
        
        case uploadButtonTapped
        case uploadResponse(Result<UploadResponse, NetworkError>) // 서버 응답 결과
        
    }
    
    @Dependency(\.captureSession) var captureSession
    @Dependency(\.fileManager) var fileManager
    @Dependency(\.networkClient) var networkClient
    
    // MARK: Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .uploadModel:
                guard let modelURL = state.modelURL else {
                    return .none
                }
                
                state.processingMessage = "Uploading to server..."
                
                return .run { send in
                    await send(.uploadStarted)
                    
                    do {
                        let response = try await networkClient.uploadModel(modelURL)
                        
                        if response.success {
                            await send(.uploadCompleted(response.message))
                        } else {
                            await send(.uploadFailed(response.message))
                        }
                    } catch {
                        await send(.uploadFailed(error.localizedDescription))
                    }
                }
                
            case .uploadStarted:
                print("업로드 시작")
                return .none
                
            case .uploadCompleted(let message):
                state.processingMessage = "업로드 완료 \(message)"
                print("업로드 완료 \(message)")
                return .none
                
            case .uploadFailed(let error):
                state.processingMessage = "업로드 실패: \(error)"
                print("업로드 실패: \(error)")
                return .none
                
            case .onAppear:
                return .send(.setupSession)
                
            case .setupSession:
                let scansFolder = fileManager.getScansDirectory()
                fileManager.clearDirectory(scansFolder)
                
                var config = ObjectCaptureSession.Configuration()
                config.isOverCaptureEnabled = (state.captureMode == .object)
                
                captureSession.start(scansFolder, config)
                print("Setup session called")
                
                return .run { send in
                    // 세션 상태 모니터링 시작
                    await send(.monitorSessionState)
                }
                
            case .monitorSessionState:
                return .none
                
            case .startDetecting:
                let success = captureSession.startDetecting()
                state.hasDetectionFailed = !success
                print("Start detecting: \(success)")
                return .none
                
            case .startCapturing:
                captureSession.startCapturing()
                state.isCapturing = true
                print("Start capturing")
                return .none
                
            case .finishCapturing:
                captureSession.finish()
                state.isCapturing = false
                state.showProcessButton = true
                print("Finish capturing")
                return .none
                
            case .setShowOverlaySheets(let show):
                guard show != state.showOverlaySheets else { return .none }
                state.showOverlaySheets = show
                
                if show {
                    captureSession.pause()
                    print("Session paused")
                } else {
                    captureSession.resume()
                    print("Session resumed")
                }
                return .none
                
            case .startReconstruction:
                state.processingMessage = "Preparing reconstruction..."
                print("Start reconstruction")
                
                let inputFolder = fileManager.getScansDirectory()
                let outputFile = fileManager.getModelOutputPath()
                
                return .run { send in
                    do {
                        let photoSession = try PhotogrammetrySession(input: inputFolder)
                        try photoSession.process(requests: [.modelFile(url: outputFile)])
                        
                        for try await output in photoSession.outputs {
                            switch output {
                            case .requestProgress(_, let fraction):
                                await send(.reconstructionProgressUpdated(Float(fraction)))
                                
                            case .processingComplete:
                                await send(.reconstructionCompleted(outputFile))
                                
                            case .requestError(_, let error):
                                await send(.reconstructionFailed(error.localizedDescription))
                                
                            default:
                                break
                            }
                        }
                    } catch {
                        await send(.reconstructionFailed(error.localizedDescription))
                    }
                }
                
            case .reset:
                // 상태 초기화
                state = State()
                return .send(.setupSession)
                
            case .sessionStateChanged:
                print("Session state changed")
                return .none
                
            case .captureProgressUpdated(let current, let total):
                state.currentImageCount = current
                state.totalImageCount = total
                state.numberOfShotsTaken = current
                return .none
                
            case .sessionMaxImagesUpdated(let max):
                state.maximumNumberOfInputImages = max
                return .none
                
            case .reconstructionProgressUpdated(let fraction):
                state.processingMessage = "Processing... \(Int(fraction * 100))%"
                return .none
                
            case .reconstructionCompleted(let url):
                state.processingMessage = "Complete! (MyModel.usdz)"
                state.modelURL = url
                state.showModelView = true
                print("Model created: \(url)")
                return .none
                
            case .reconstructionFailed(let error):
                state.processingMessage = "Error: \(error)"
                print("Reconstruction error: \(error)")
                return .none
                
            case .toggleCaptureMode:
                state.captureMode = state.captureMode.nextMode
                return .send(.reset)
                
            case .resetState:
                state.currentOrbit = .orbit1
                state.isObjectFlipped = false
                state.hasIndicatedObjectCannotBeFlipped = false
                state.hasIndicatedFlipObjectAnyway = false
                state.tutorialPlayedOnce = false
                return .none
                
            case .setCurrentOrbit(let orbit):
                state.currentOrbit = orbit
                return .none
                
            case .flipObject:
                state.isObjectFlipped.toggle()
                return .none
                
            case .uploadButtonTapped:
                guard let url = state.modelURL else { return .none }
                
                state.isUploading = true
                state.uploadMessage = "업로드 시작"
                
                return .run { send in
                    do {
                        let response = try await networkClient.uploadModel(url)
                        await send(.uploadResponse(.success(response)))
                    } catch let error as NetworkError {
                        await send(.uploadResponse(.failure(error)))
                    } catch {
                        // 알 수 없는 에러 처리
                        await send(.uploadResponse(.failure(.invalidResponse)))
                    }
                }
                
            case .uploadResponse(.success(let response)):
                state.isUploading = false
                state.uploadMessage = "업로드 성공: \(response.message)"
                return .none

            case .uploadResponse(.failure(let error)):
                state.isUploading = false
                state.uploadMessage = "업로드 실패: \(error.localizedDescription)"
                return .none
            }
        }
    }
}
