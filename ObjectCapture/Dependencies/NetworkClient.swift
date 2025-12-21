//
//  NetworkClient.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/21/25.
//

import Foundation
import ComposableArchitecture

struct NetworkClient {
    var uploadModel: @Sendable (URL) async throws -> UploadResponse
}

struct UploadResponse: Codable, Equatable {
    let success: Bool
    let message: String
    let fileId: String?
}

extension NetworkClient: DependencyKey {
    static let liveValue = Self(
        uploadModel: { fileURL in
            let serverURL = URL(string: "http://192.0.0.2:8000/upload-model")!
            
            var request = URLRequest(url: serverURL)
            request.httpMethod = "POST"
            
            let boundary = UUID().uuidString
            
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // Multipart form data 생성
            var body = Data()
            
            // 파일 데이터 추가
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: model/vnd.usdz+zip\r\n\r\n".data(using: .utf8)!)
            
            let fileData = try Data(contentsOf: fileURL)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
            
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            // 타임아웃 설정 (큰 파일을 위해)
            request.timeoutInterval = 60
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw NetworkError.httpError(statusCode: httpResponse.statusCode)
            }
            
            let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
            return uploadResponse
        }
    )
    
    static let testValue = Self(
        uploadModel: { _ in
            UploadResponse(success: true, message: "Test upload", fileId: "test-123")
        }
    )
}

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "Server error: \(code)"
        }
    }
}

extension DependencyValues {
    var networkClient: NetworkClient {
        get { self[NetworkClient.self] }
        set { self[NetworkClient.self] = newValue }
    }
}
