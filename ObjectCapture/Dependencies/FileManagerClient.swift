//
//  FileManagerClient.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/15/25.
//

import Foundation
import ComposableArchitecture

struct FileManagerClient {
    var getDocumentsDirectory: @Sendable () -> URL
    var getScansDirectory: @Sendable () -> URL
    var getModelOutputPath: @Sendable () -> URL
    var clearDirectory: @Sendable (URL) -> Void
}

extension FileManagerClient: DependencyKey {
    static let liveValue = Self(
        getDocumentsDirectory: {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        },
        getScansDirectory: {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return docs.appendingPathComponent("Scans")
        },
        getModelOutputPath: {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return docs.appendingPathComponent("MyModel.usdz")
        },
        clearDirectory: { url in
            let fm = FileManager.default
            if fm.fileExists(atPath: url.path) {
                try? fm.removeItem(at: url)
            }
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    )
}

extension DependencyValues {
    var fileManager: FileManagerClient {
        get { self[FileManagerClient.self] }
        set { self[FileManagerClient.self] = newValue }
    }
}
