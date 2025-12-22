//
//  NetworkClient.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/21/25.
//

import Foundation
import ComposableArchitecture

// 1. 서버가 돌려줄 응답의 형식을 정의
struct UploadResponse: Codable, Equatable {
    let success: Bool
    let message: String
    let fileId: String?
}

// 2. 클라이언트의 인터페이스를 정의합니다.
struct NetworkClient {
    // URL(파일위치)을 받아서 UploadResponse를 돌려주는 비동기 함수
    var uploadModel: @Sendable (URL) async throws -> UploadResponse
}

// 3. 의존성 주입을 위한 준비 (TCA 방식)
extension DependencyValues {
    var networkClient: NetworkClient {
        get { self[NetworkClient.self] }
        set { self[NetworkClient.self] = newValue }
    }
}

extension NetworkClient: DependencyKey {
    
    static let liveValue = Self(
        uploadModel: { fileURL in
            let serverURL = URL(string: "http://192.168.XX.XX:8000/upload-model")!
            
            // HTTP Request 설정
            var request = URLRequest(url: serverURL)
            request.httpMethod = "POST"
            
            let boundary = "Boundary-\(UUID().uuidString)"
            
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            // 서버의 파라미터 이름인 "file"과 실제 파일 이름을 지정
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: model/vnd.usdz+zip\r\n\r\n".data(using: .utf8)!)
            
            // 아이폰 내부에 저장된 .usdz 파일을 Binary로 읽어옴
            let fileData = try Data(contentsOf: fileURL)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
            
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            request.timeoutInterval = 300 // 전송 시간 5분
            
            // URLSession을 통해 실제 데이터 전송
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 서버 응답 확인
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                // 응답이 정상이 아니면 에러 throw
                throw NetworkError.invalidResponse
            }
            
            // 서버가 준 JSON 데이터를 UploadResponse 구조체로 변환
            let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
            
            return uploadResponse
        }
    )
}

enum NetworkError: Error, Equatable {
    case invalidResponse
}
