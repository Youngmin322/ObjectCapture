//
//  ObjectCaptureApp.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/1/25.
//

import SwiftUI
import SwiftData

@main
struct ObjectCaptureApp: App {
    @State private var appModel = AppDataModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
    }
}
