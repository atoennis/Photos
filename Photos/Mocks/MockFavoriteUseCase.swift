// Mocks/MockFavoriteUseCase.swift
import Foundation

#if DEBUG
struct MockFavoriteUseCase: FavoriteUseCase {
    var delay: TimeInterval? = nil
    var favorites: [Photo] = []
    var throwError: Bool = false
    var favoriteIds: Set<String> = []

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
        return favoriteIds.contains(photoId) || favorites.contains { $0.id == photoId }
    }

    func toggleFavorite(_ photo: Photo) async throws {
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
