//
//  AppDataModel.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/4/25.
//

import Foundation

@Observable
class AppDataModel {
    enum CaptureMode: Equatable {
        case object
        case area
    }
    
    var captureMode: CaptureMode = .object
    var isObjectFlipped: Bool = false
}
