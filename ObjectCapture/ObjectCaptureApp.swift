//
//  ObjectCaptureApp.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/1/25.
//

import SwiftUI
import ComposableArchitecture

@main
struct ObjectCaptureApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(
                    Store(initialState: AppFeature.State()) {
                        AppFeature()
                    }
                )
        }
    }
}
