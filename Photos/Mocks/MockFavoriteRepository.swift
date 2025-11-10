// Mocks/MockFavoriteRepository.swift
import Foundation

#if DEBUG
struct MockFavoriteRepository: FavoriteRepository {
    var delay: TimeInterval? = nil
    var favorites: [Photo] = []
    var throwError: Bool = false

    func getFavorites() async throws -> [Photo] {
        if let delay {
            try await Task.sleep(for: .seconds(delay))
        }
        guard !throwError else {
            throw MockError.mockError
        }
        return favorites
    }

    func isFavorite(photoId: String) async throws -> Bool {
        if let delay {
            try await Task.sleep(for: .seconds(delay))
        }
        guard !throwError else {
            throw MockError.mockError
        }
        return favorites.contains { $0.id == photoId }
    }

    func addFavorite(_ photo: Photo) async throws {
        if let delay {
            try await Task.sleep(for: .seconds(delay))
        }
        guard !throwError else {
            throw MockError.mockError
        }
        // Mock implementation - just succeeds
    }

    func removeFavorite(photoId: String) async throws {
        if let delay {
            try await Task.sleep(for: .seconds(delay))
        }
        guard !throwError else {
            throw MockError.mockError
        }
        // Mock implementation - just succeeds
    }
}
#endif
