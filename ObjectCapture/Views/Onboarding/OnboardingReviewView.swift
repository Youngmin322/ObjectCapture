//
//  OnboardingReviewView.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/11/25.
//

import SwiftUI
import RealityKit

// MARK: - Onboarding Review View
struct OnboardingReviewView: View {
    var session: ObjectCaptureSession
    @Binding var showOnboardingView: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("촬영 진행 상황")
                .font(.largeTitle)
                .bold()
            
            Text("촬영한 사진: \(session.numberOfShotsTaken)장")
                .font(.headline)
            
            Divider()
            
            VStack(spacing: 15) {
                Button("계속 촬영하기 (Continue)") {
                    showOnboardingView = false
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
                
                Button("촬영 완료 (Finish)") {
                    session.finish()
                    showOnboardingView = false
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .padding()
        }
        .padding()
    }
}
