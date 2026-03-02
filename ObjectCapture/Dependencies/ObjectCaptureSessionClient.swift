//
//  ObjectCaptureSessionClient.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/15/25.
//

import SwiftUI
import RealityKit
import ComposableArchitecture

struct ObjectCaptureSessionClient {
    // 메인 세션 인스턴스에 대한 동기 제어 메서드
    var start: @MainActor @Sendable (URL, ObjectCaptureSession.Configuration) -> Void
    var startDetecting: @MainActor @Sendable () -> Bool
    var startCapturing: @MainActor @Sendable () -> Void
    var finish: @MainActor @Sendable () -> Void
    var pause: @MainActor @Sendable () -> Void
    var resume: @MainActor @Sendable () -> Void
    var requestImageCapture: @MainActor @Sendable () -> Void

    // 현재 세션 상태 조회
    var state: @MainActor @Sendable () -> ObjectCaptureSession.CaptureState
    var numberOfShotsTaken: @MainActor @Sendable () -> Int
    var maximumNumberOfInputImages: @MainActor @Sendable () -> Int

    // 세션에서 오는 비동기 스트림 (MainActor에서만 접근)
    var stateUpdates: @MainActor @Sendable () -> ObjectCaptureSession.Updates<ObjectCaptureSession.CaptureState>
    var userCompletedScanPassUpdates: @MainActor @Sendable () -> ObjectCaptureSession.Updates<Bool>
}

extension ObjectCaptureSessionClient: DependencyKey {
    @MainActor
    static let liveValue: Self = {
        let session = ObjectCaptureSession()

        return Self(
            start: { url, config in
                session.start(imagesDirectory: url, configuration: config)
            },
            startDetecting: {
                session.startDetecting()
            },
            startCapturing: {
                session.startCapturing()
            },
            finish: {
                session.finish()
            },
            pause: {
                session.pause()
            },
            resume: {
                session.resume()
            },
            requestImageCapture: {
                session.requestImageCapture()
            },
            state: {
                session.state
            },
            numberOfShotsTaken: {
                session.numberOfShotsTaken
            },
            maximumNumberOfInputImages: {
                session.maximumNumberOfInputImages
            },
            stateUpdates: {
                session.stateUpdates
            },
            userCompletedScanPassUpdates: {
                session.userCompletedScanPassUpdates
            }
        )
    }()

    @MainActor
    static let testValue: Self = {
        let session = ObjectCaptureSession()

        return Self(
            start: { _, _ in },
            startDetecting: { true },
            startCapturing: { },
            finish: { },
            pause: { },
            resume: { },
            requestImageCapture: { },
            state: { .ready },
            numberOfShotsTaken: { 0 },
            maximumNumberOfInputImages: { 100 },
            stateUpdates: {
                session.stateUpdates
            },
            userCompletedScanPassUpdates: {
                session.userCompletedScanPassUpdates
            }
        )
    }()
}

extension DependencyValues {
    var captureSession: ObjectCaptureSessionClient {
        get { self[ObjectCaptureSessionClient.self] }
        set { self[ObjectCaptureSessionClient.self] = newValue }
    }
}
