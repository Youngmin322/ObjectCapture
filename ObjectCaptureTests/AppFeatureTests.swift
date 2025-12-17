//
//  AppFeatureTests.swift
//  ObjectCaptureTests
//
//  Created by Youngmin Cho on 12/15/25.
//

import Testing
import SwiftUI
import ComposableArchitecture
import RealityKit
@testable import ObjectCapture

@MainActor
@Suite
struct AppFeatureTests {
    
    @Test("캡쳐 모드 토글 및 자동 세션 초기화 검증")
    func testToggleCaptureMode() async {
        // Mock RealityKit ObjectCaptureSession 인스턴스
        let mockSession = ObjectCaptureSession()
        
        // TestStore 초기화 및 Dependencies Mock 주입
        let store = TestStore(
            initialState: AppFeature.State(captureMode: .object) // Object 모드로 시작
        ) {
            AppFeature()
        } withDependencies: {
            // MARK: - Dependencies Mocking (테스트 환경 설정)
            
            // FileManagerClient Mock 정의
            $0.fileManager = FileManagerClient(
                getDocumentsDirectory: { URL(fileURLWithPath: "/mock/docs") },
                getScansDirectory: { URL(fileURLWithPath: "/mock/scans") },
                getModelOutputPath: { URL(fileURLWithPath: "/mock/model.usdz") },
                clearDirectory: { _ in }
            )
            
            // ObjectCaptureSessionClient Mock 정의
            $0.captureSession = ObjectCaptureSessionClient(
                session: { mockSession },
                start: { _, _ in },
                startDetecting: { true },
                startCapturing: { },
                finish: { },
                pause: { },
                resume: { },
                state: { .ready },
                numberOfShotsTaken: { 0 },
                maximumNumberOfInputImages: { 100 }
            )
        }
        
        // MARK: 1차 모드 토글: Object -> Area
        
        await store.send(.toggleCaptureMode) {
            // 1. Reducer 실행: captureMode가 다음 모드(.area)로 변경됨을 기대
            $0.captureMode = .area
        }
        
        // 2. .toggleCaptureMode의 Effect(.send(.reset))를 수신
        await store.receive(\.reset) {
            // .reset 액션이 Reducer에서 모든 상태(state = State())를 초기화했음을 명시적으로 검증
            $0 = AppFeature.State()
        }
        
        // 3. .reset의 Effect로 발생한 세션 설정 액션(.setupSession) 수신
        await store.receive(\.setupSession)
        
        // 4. .setupSession의 Effect로 발생한 세션 모니터링 시작 액션(.monitorSessionState) 수신
        await store.receive(\.monitorSessionState)
        
        
        // MARK: 2차 모드 토글: (현재 .object) -> Area
        
        await store.send(.toggleCaptureMode) {
            // 5. Reducer 실행: captureMode가 다음 모드(.area)로 변경됨을 기대
            $0.captureMode = .area
        }
        
        // 6. 2차 .reset 액션 수신 및 전체 상태 초기화 검증
        await store.receive(\.reset) {
            // 모든 상태를 초기값으로 리셋했는지 검증
            $0 = AppFeature.State()
        }
        
        // 7. 2차 세션 설정 및 모니터링 액션 수신
        await store.receive(\.setupSession)
        await store.receive(\.monitorSessionState)
    }
}
