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
        // 캡처 모드 / 오빗 등
        var captureMode: CaptureMode = .object
        var currentOrbit: Orbit = .orbit1
        var isObjectFlipped: Bool = false
        var isObjectFlippable: Bool = true
        var hasIndicatedObjectCannotBeFlipped: Bool = false
        var hasIndicatedFlipObjectAnyway: Bool = false
        var tutorialPlayedOnce: Bool = false

        // 세션 상태에 따른 UI
        var sessionState: ObjectCaptureSession.CaptureState = .ready
        var isCapturing: Bool = false
        var showProcessButton: Bool = false
        var hasDetectionFailed: Bool = false
        var processingMessage: String = ""
        var showOverlaySheets: Bool = false

        // 캡처 진행도
        var currentImageCount: Int = 0
        var totalImageCount: Int = 0
        var maximumNumberOfInputImages: Int = 100

        // 3D 모델
        var modelURL: URL?
        var showModelView: Bool = false

        // 업로드
        var isUploading: Bool = false
        var uploadMessage: String = ""

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

        // 버튼 레이블 등 UI 계산 프로퍼티
        var captureButtonTitle: String? {
            switch sessionState {
            case .ready:
                return captureMode == .object ? "Continue" : "Start Capture"
            case .detecting:
                return "Start Capture"
            case .capturing:
                return nil
            default:
                return nil
            }
        }
    }

    // MARK: Action
    enum Action: Equatable {
        // 라이프사이클
        case onAppear
        case setupSession
        case reset

        // 세션 내 상태 업데이트(내부용)
        case sessionStateUpdated(ObjectCaptureSession.CaptureState)
        case captureProgressUpdated(current: Int, total: Int)
        case scanPassCompleted(Bool)

        // 사용자의 입력
        case captureModeButtonTapped           // 모드 토글 버튼
        case captureButtonTapped               // 가운데 큰 버튼
        case cancelButtonTapped                // 상단 취소 버튼
        case finishCapturingTapped             // 온보딩에서 "Finish"
        case toggleOverlaySheets(Bool)         // 시트 표시/숨김
        case reconstructionButtonTapped        // "3D 모델 생성"
        case startOverButtonTapped             // "새로 시작"
        case modelSheetDismissed               // ARQuickLook 닫기

        // Photogrammetry
        case reconstructionProgressUpdated(Float)
        case reconstructionCompleted(URL)
        case reconstructionFailed(String)

        // 업로드
        case uploadButtonTapped
        case uploadResponse(Result<UploadResponse, NetworkError>)
    }

    // MARK: Dependencies
    @Dependency(\.captureSession) var captureSession
    @Dependency(\.fileManager) var fileManager
    @Dependency(\.networkClient) var networkClient

    // MARK: Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: 라이프사이클

            case .onAppear:
                return .send(.setupSession)

            case .setupSession:
                let scansFolder = fileManager.getScansDirectory()
                fileManager.clearDirectory(scansFolder)

                var config = ObjectCaptureSession.Configuration()
                config.isOverCaptureEnabled = (state.captureMode == .object)

                captureSession.start(scansFolder, config)
                state.sessionState = captureSession.state()
                state.currentImageCount = captureSession.numberOfShotsTaken()
                state.totalImageCount = captureSession.maximumNumberOfInputImages()
                state.maximumNumberOfInputImages = captureSession.maximumNumberOfInputImages()

                // 세션 상태 / 패스 완료 스트림 구독
                return .merge(
                    .run { [captureSession] send in
                        for await s in captureSession.stateUpdates() {
                            await send(.sessionStateUpdated(s))
                            let current = captureSession.numberOfShotsTaken()
                            let total = captureSession.maximumNumberOfInputImages()
                            await send(.captureProgressUpdated(current: current, total: total))
                        }
                    }
                    .cancellable(id: "session"),

                    .run { [captureSession] send in
                        for await done in captureSession.userCompletedScanPassUpdates() {
                            await send(.scanPassCompleted(done))
                        }
                    }
                    .cancellable(id: "session")
                )

            case .reset:
                // 세션 관련 이펙트 취소 후, 상태 초기화 + 새 세션 준비
                state = State(captureMode: state.captureMode)
                return .merge(
                    .cancel(id: "session"),
                    .cancel(id: "reconstruction"),
                    .cancel(id: "upload"),
                    .send(.setupSession)
                )

            // MARK: 세션 내부 상태 업데이트 (내부 액션)
            case let .sessionStateUpdated(newState):
                state.sessionState = newState
                switch newState {
                case .capturing:
                    state.isCapturing = true
                case .completed:
                    state.isCapturing = false
                    state.showProcessButton = true
                default:
                    break
                }
                return .none

            case let .captureProgressUpdated(current, total):
                state.currentImageCount = current
                state.totalImageCount = total
                state.maximumNumberOfInputImages = max(state.maximumNumberOfInputImages, total)
                return .none

            case let .scanPassCompleted(done):
                if done {
                    state.showOverlaySheets = true
                }
                return .none

            // MARK: 사용자 입력 - 세션 제어
            case .captureModeButtonTapped:
                state.captureMode = state.captureMode.nextMode
                return .send(.reset)

            case .captureButtonTapped:
                let sessionState = captureSession.state()
                switch sessionState {
                case .ready:
                    if state.captureMode == .object {
                        let success = captureSession.startDetecting()
                        state.hasDetectionFailed = !success
                    } else {
                        captureSession.startCapturing()
                        state.isCapturing = true
                    }
                case .detecting:
                    captureSession.startCapturing()
                    state.isCapturing = true
                default:
                    break
                }
                return .none

            case .cancelButtonTapped:
                captureSession.finish()
                state.isCapturing = false
                state.showProcessButton = false
                return .none

            case .finishCapturingTapped:
                captureSession.finish()
                state.isCapturing = false
                state.showProcessButton = true
                state.showOverlaySheets = false
                return .none

            case let .toggleOverlaySheets(show):
                guard show != state.showOverlaySheets else { return .none }
                state.showOverlaySheets = show
                if show {
                    captureSession.pause()
                } else {
                    captureSession.resume()
                }
                return .none

            case .startOverButtonTapped:
                return .send(.reset)

            case .modelSheetDismissed:
                state.showModelView = false
                return .none

            // MARK: Photogrammetry

            case .reconstructionButtonTapped:
                guard state.modelURL == nil else {
                    state.showModelView = true
                    return .none
                }

                state.processingMessage = "Preparing reconstruction..."
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
                .cancellable(id: "reconstruction")

            case let .reconstructionProgressUpdated(fraction):
                state.processingMessage = "Processing... \(Int(fraction * 100))%"
                return .none

            case let .reconstructionCompleted(url):
                state.processingMessage = "Complete! (MyModel.usdz)"
                state.modelURL = url
                state.showModelView = true
                return .none

            case let .reconstructionFailed(message):
                state.processingMessage = "Error: \(message)"
                return .none

            // MARK: 업로드

            case .uploadButtonTapped:
                guard let url = state.modelURL, !state.isUploading else { return .none }

                state.isUploading = true
                state.uploadMessage = "Uploading..."

                return .run { [networkClient] send in
                    do {
                        let response = try await networkClient.uploadModel(url)
                        await send(.uploadResponse(.success(response)))
                    } catch let error as NetworkError {
                        await send(.uploadResponse(.failure(error)))
                    } catch {
                        await send(.uploadResponse(.failure(.invalidResponse)))
                    }
                }
                .cancellable(id: "upload")

            case let .uploadResponse(.success(response)):
                state.isUploading = false
                state.uploadMessage = "✓ \(response.message)"
                return .none

            case let .uploadResponse(.failure(error)):
                state.isUploading = false
                state.uploadMessage = "업로드 실패: \(error.localizedDescription)"
                return .none
            }
        }
    }
}
