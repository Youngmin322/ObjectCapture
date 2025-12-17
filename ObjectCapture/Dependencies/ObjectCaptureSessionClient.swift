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
    var session: @MainActor @Sendable () -> ObjectCaptureSession
    var start: @MainActor @Sendable (URL, ObjectCaptureSession.Configuration) -> Void
    var startDetecting: @MainActor @Sendable () -> Bool
    var startCapturing: @MainActor @Sendable () -> Void
    var finish: @MainActor @Sendable () -> Void
    var pause: @MainActor @Sendable () -> Void
    var resume: @MainActor @Sendable () -> Void
    var state: @MainActor @Sendable () -> ObjectCaptureSession.CaptureState
    var numberOfShotsTaken: @MainActor @Sendable () -> Int
    var maximumNumberOfInputImages: @MainActor @Sendable () -> Int
}

extension ObjectCaptureSessionClient: DependencyKey {
    @MainActor static let liveValue: Self = {
        let session = ObjectCaptureSession()
        
        return Self(
            session: { session },
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
            state: {
                session.state
            },
            numberOfShotsTaken: {
                session.numberOfShotsTaken
            },
            maximumNumberOfInputImages: {
                session.maximumNumberOfInputImages
            }
        )
    }()
    
    @MainActor
    static let testValue = Self(
        session: { ObjectCaptureSession() },
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

extension DependencyValues {
    var captureSession: ObjectCaptureSessionClient {
        get { self[ObjectCaptureSessionClient.self] }
        set { self[ObjectCaptureSessionClient.self] = newValue }
    }
}

