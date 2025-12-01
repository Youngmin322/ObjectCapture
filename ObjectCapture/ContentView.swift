//
//  ContentView.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/1/25.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var session = ObjectCaptureSession()
    @State private var isCapturing = false // UI 상태 관리

    var body: some View {
        ZStack {
            // 카메라 화면
            ObjectCaptureView(session: session)
            // UI 레이어
            VStack {
                Spacer()
                
                Button(action: {
                    if isCapturing {
                        session.finish()
                        print("촬영 종료")
                    } else {
                        session.startCapturing()
                        print("촬영 시작")
                    }
                    isCapturing.toggle() // 상태 토글
                }) {
                    Text(isCapturing ? "완료 (Finish)" : "촬영 시작 (Start)")
                        .font(.title3)
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isCapturing ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            // 폴더 만들고 세션 준비
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let scansFolder = documentsPath.appendingPathComponent("Scans")
            try? FileManager.default.createDirectory(at: scansFolder, withIntermediateDirectories: true)
            
            var config = ObjectCaptureSession.Configuration()
            config.isOverCaptureEnabled = true
            session.start(imagesDirectory: scansFolder, configuration: config)
        }
    }
}
