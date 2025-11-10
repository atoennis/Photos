// Domain/UseCases/FavoriteUseCase.swift
import Foundation

/// Protocol composition for dependency injection
protocol HasFavoriteUseCase {
    var favoriteUseCase: FavoriteUseCase { get }
}

/// Use case for managing favorite photos
/// Business logic layer - coordinates with FavoriteRepository
protocol FavoriteUseCase: Sendable {
    func getFavorites() async throws -> [Photo]
    func isFavorite(photoId: String) async throws -> Bool
    func toggleFavorite(_ photo: Photo) async throws
}

/// Default implementation of FavoriteUseCase
struct DefaultFavoriteUseCase: FavoriteUseCase {
    let repository: FavoriteRepository

    func getFavorites() async throws -> [Photo] {
        try await repository.getFavorites()
    }

    func isFavorite(photoId: String) async throws -> Bool {
        try await repository.isFavorite(photoId: photoId)
    }

    /// Toggle favorite status - add if not favorited, remove if already favorited
    func toggleFavorite(_ photo: Photo) async throws {
        let isFavorited = try await repository.isFavorite(photoId: photo.id)

        if isFavorited {
            try await repository.removeFavorite(photoId: photo.id)
        } else {
            try await repository.addFavorite(photo)
        }
    }
}
