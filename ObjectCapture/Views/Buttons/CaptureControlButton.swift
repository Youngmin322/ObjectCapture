//
//  CaptureControlButton.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/22/25.
//

import SwiftUI
import RealityKit
import ComposableArchitecture

struct CaptureControlButton: View {
    let store: Store<AppFeature.State, AppFeature.Action>
    var session: ObjectCaptureSession
    
    var body: some View {
        ZStack {
            // 1. 촬영 중(capturing)일 때는 수동 셔터 버튼
            if case .capturing = session.state {
                Button(action: {
                    session.requestImageCapture()
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 48, height: 48)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                    }
                }
            }
            // 2. 촬영 전/대기 중일 때는 모드 전환(Object/Area) 버튼
            else {
                Button(action: {
                    store.send(.captureButtonTapped)
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: store.captureMode == .object ? "cube" : "circle.dashed")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .animation(.spring(), value: session.state)
    }
}
