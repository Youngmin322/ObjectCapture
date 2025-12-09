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
        getDocumentsDirectory().appendingPathComponent("MyModel.usdz")
    }
    
    // MARK: - Directory Operations
    func clearDirectory(_ url: URL) {
        if fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
