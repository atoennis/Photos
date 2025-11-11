// Mocks/MockNetworkSession.swift
#if DEBUG
import Foundation

struct MockNetworkSession: NetworkSession {
    var throwError: Bool = false
    var statusCode: Int = 200
    var responseData: Data

    // Convenience init that accepts Encodable fixtures and converts to JSON
    init<T: Encodable>(
        response: T,
        statusCode: Int = 200,
        throwError: Bool = false
    ) throws {
        self.throwError = throwError
        self.statusCode = statusCode
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.responseData = try encoder.encode(response)
    }

    // Init with raw Data for edge cases (invalid JSON, etc.)
    init(responseData: Data = Data(), statusCode: Int = 200, throwError: Bool = false) {
        self.throwError = throwError
        self.statusCode = statusCode
        self.responseData = responseData
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard !throwError else {
            throw URLError(.badServerResponse)
        }

        guard let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
              ) else {
            throw URLError(.badServerResponse)
        }

        return (responseData, response)
    }
}

enum MockError: Error {
    case mockError
}
#endif
