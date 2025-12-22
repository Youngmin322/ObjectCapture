//
//  UploadControlView.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/22/25.
//

import SwiftUI
import ComposableArchitecture

struct UploadControlView: View {
    // TCA Store 연결
    @Environment(Store<AppFeature.State, AppFeature.Action>.self) var store
    
    var body: some View {
        VStack {
            Spacer() // 버튼을 화면 하단으로 밀어내기 위함
            
            Button(action: {
                // 버튼 클릭 시 애니메이션과 함께 액션 전송
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    _ = store.send(.uploadButtonTapped)
                }
            }) {
                HStack(spacing: 12) {
                    // 업로드 중일 때만 인디케이터 표시
                    if store.isUploading {
                        ProgressView()
                            .tint(.white)
                    }
                    
                    Text(store.isUploading ? "전송 중..." : "서버로 모델 보내기")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                // 상태에 따른 배경색 변경 (심플 버전)
                .background(store.isUploading ? Color(.systemGray4) : Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                // 업로드 중에는 그림자를 제거하여 '눌린' 느낌 제공
                .shadow(color: .black.opacity(store.isUploading ? 0 : 0.15), radius: 10, y: 5)
            }
            .disabled(store.isUploading) // 중복 클릭 방지
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        // 버튼이 나타나고 사라질 때의 부드러운 전환 효과
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Previews
#Preview("일반 상태") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        UploadControlView()
            .environment(
                Store(initialState: AppFeature.State(
                    modelURL: URL(string: "file:///test.usdz"),
                    isUploading: false
                )) {
                    AppFeature()
                }
            )
    }
}

#Preview("업로드 중") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        UploadControlView()
            .environment(
                Store(initialState: AppFeature.State(
                    modelURL: URL(string: "file:///test.usdz"),
                    isUploading: true
                )) {
                    AppFeature()
                }
            )
    }
}
