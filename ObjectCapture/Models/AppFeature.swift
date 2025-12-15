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
    enum Action {
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
    }
    
    // MARK: Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .setupSession:
                print("Setup session called")
                return .none
                
            case .startDetecting:
                print("start detecting called")
                return .none
                
            case .startCapturing:
                state.isCapturing = true
                return .none
                
            case .finishCapturing:
                state.isCapturing = false
                state.showProcessButton = true
                print("Finish Capturing")
                return .none
                
            case .setShowOverlaySheets(let show):
                guard show != state.showOverlaySheets else { return .none }
                state.showOverlaySheets = show
                return .none
                
            case .startReconstruction:
                state.processingMessage = "Preparing reconstruction"
                print("start reconstruction")
                return .none
                
            case .reset:
                // 상태 초기화
                state = State()
                return .none
                
            case .sessionStateChanged:
                print("Session state changed")
                return .none
                
            case .captureProgressUpdated(let current, let total):
                state.currentImageCount = current
                state.totalImageCount = total
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
                // 캡처 모드 변경
                state.captureMode = state.captureMode.nextMode
                return .none
                
            case .resetState:
                // 상태 초기화
                state.currentOrbit = .orbit1
                state.isObjectFlipped = false
                state.hasIndicatedObjectCannotBeFlipped = false
                state.hasIndicatedFlipObjectAnyway = false
                state.tutorialPlayedOnce = false
                return .none
                
            case .setCurrentOrbit(let orbit):
                // 현재 orbit 변경
                state.currentOrbit = orbit
                return .none
                
            case .flipObject:
                // 객체 뒤집기
                state.isObjectFlipped.toggle()
                return .none
            }
        }
    }
}
