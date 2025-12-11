//
//  AppDataModel.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/4/25.
//

import SwiftUI
import RealityKit

@MainActor
@Observable
class AppDataModel {
    // MARK: - Capture Mode
    enum CaptureMode: Equatable {
        case object
        case area
    }
    
    var captureMode: CaptureMode = .object
    
    // MARK: - Orbit State
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
    
    var currentOrbit: Orbit = .orbit1
    var isObjectFlipped: Bool = false
    
    // MARK: - Object Properties
    var isObjectFlippable: Bool = true
    var hasIndicatedObjectCannotBeFlipped: Bool = false
    var hasIndicatedFlipObjectAnyway: Bool = false
    
    // MARK: - Tutorial State
    var tutorialPlayedOnce: Bool = false
    
    // MARK: - Minimum Images Required
    static let minNumImages = 10
    
    // MARK: - Helper Methods
    func resetState() {
        currentOrbit = .orbit1
        isObjectFlipped = false
        hasIndicatedObjectCannotBeFlipped = false
        hasIndicatedFlipObjectAnyway = false
        tutorialPlayedOnce = false
    }
    
    func canProceedToNextOrbit(session: ObjectCaptureSession) -> Bool {
        return session.numberOfShotsTaken >= Self.minNumImages
    }
}
