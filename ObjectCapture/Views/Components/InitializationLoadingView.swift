//
//  InitializationLoadingView.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/4/25.
//

import SwiftUI

struct InitializationLoadingView: View {
    @State private var isPulsing = false
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 아이콘 + 로딩 인디케이터
            ZStack {
                // 배경 링 (펄싱)
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(isPulsing ? 1.15 : 1.0)
                    .opacity(isPulsing ? 0.6 : 1.0)

                // 회전하는 점선 링
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        style: StrokeStyle(lineWidth: 3, dash: [6, 4])
                    )
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(rotation))

                // 중앙 아이콘
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("카메라 준비 중")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("3D 캡처를 위해 세션을 초기화하고 있습니다")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
}

#Preview {
    InitializationLoadingView()
}
