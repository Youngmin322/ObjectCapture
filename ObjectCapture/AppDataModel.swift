//
//  AppDataModel.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/1/25.
//

import RealityKit
import SwiftUI

@MainActor
@Observable
class AppDataModel: Identifiable {
    // 앱 전체에서 접근할 수 있는 싱글톤 인스턴스
    static let instance = AppDataModel()
    
    enum ModelState {
        case notSet
        case ready // 앱이 준비된 상태
        case capturing // 현재 캡처 중인 상태
        case prepareToReconstruct // 재구성 준비 중
        case reconstructing // 재구성 중
        case viewing // 모델을 보고 있는 상태
        case failed // 오류 발생
        case restart // 재시작 필요
    }
    
    // 캡처 모드
    enum CaptureMode: CaseIterable {
        case object // 회전하는 객체 캡처 모드
        case area   // 영역 캡처 모드(주변 환경 스캔용)
    }
    
    // 최소 이미지 수
    static let minNumImages = 10
    
    var state: ModelState = .ready
    // 현재 캡처 모드
    var captureMode: CaptureMode = .object
    
    var objectCaptureSession: ObjectCaptureSession?
    
    var error: Swift.Error? = nil
    
    // UI 표시용 상태
    var showOverlaySheets: Bool = false
    
}
