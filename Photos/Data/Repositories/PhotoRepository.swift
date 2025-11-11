// Data/Repositories/PhotoRepository.swift
import Foundation

enum APIEnvironment {
    case production

    var baseURL: String {
        switch self {
        case .production:
            return "picsum.photos"
        }
    }
}

enum PhotoEndpoint {
    case list
    case detail(id: String)

    var path: String {
        switch self {
        case .list:
            return "/v2/list"
        case .detail(let id):
            return "/id/\(id)/info"
        }
    }
}

protocol PhotoRepository: Sendable {
    func fetchPhotoDetail(id: String) async throws -> Photo
    func fetchPhotos() async throws -> [Photo]
}

enum PhotoRepositoryError: Error {
    case badUrl
    case networkError
    case decodingError
}

struct DefaultPhotoRepository: PhotoRepository {
    let session: NetworkSession
    let environment: APIEnvironment

    private func buildURL(for endpoint: PhotoEndpoint) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = environment.baseURL
        components.path = endpoint.path

        guard let url = components.url else {
            throw PhotoRepositoryError.badUrl
        }
        return url
    }

    func fetchPhotoDetail(id: String) async throws -> Photo {
        // 1. Build URL and request
        let url = try buildURL(for: .detail(id: id))
        let request = URLRequest(url: url)

        // 2. Execute network call
        let (data, response) = try await session.data(for: request)

        // 3. Validate response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PhotoRepositoryError.networkError
        }

        // 4. Decode JSON to DTO
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            // API returns single object
            let json = try decoder.decode(PhotoJSON.self, from: data)
            // 5. Map DTO to domain model
            return json.toPhoto()
        } catch {
            throw PhotoRepositoryError.decodingError
        }
    }

    func fetchPhotos() async throws -> [Photo] {
        // 1. Build URL and request
        let url = try buildURL(for: .list)
        let request = URLRequest(url: url)

        // 2. Execute network call
        let (data, response) = try await session.data(for: request)

        // 3. Validate response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PhotoRepositoryError.networkError
        }

        // 4. Decode JSON to DTOs
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            // API returns array directly
            let json = try decoder.decode([PhotoJSON].self, from: data)
            // 5. Map DTOs to domain models
            return json.toPhotos()
        } catch {
            throw PhotoRepositoryError.decodingError
        }
    }
}
