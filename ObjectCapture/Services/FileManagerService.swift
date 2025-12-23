//
//  FileManagerService.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/4/25.
//

import Foundation

struct FileManagerService {
    private let fileManager = FileManager.default
    
    // MARK: - Directory Paths
    func getDocumentsDirectory() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func getScansDirectory() -> URL {
        getDocumentsDirectory().appendingPathComponent("Scans")
    }
    
    func getModelOutputPath() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "MyModel-\(UUID().uuidString).usdz"
        return documents.appendingPathComponent(fileName)
    }
    
    // MARK: - Directory Operations
    func clearDirectory(_ url: URL) {
        if fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
