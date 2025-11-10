// Data/Repositories/FavoriteRepository.swift
import Foundation
import SwiftData

/// Repository protocol for managing favorite photos
/// Follows Clean Architecture: protocol defined here, but referenced from Domain layer
protocol FavoriteRepository: Sendable {
    func getFavorites() async throws -> [Photo]
    func isFavorite(photoId: String) async throws -> Bool
    func addFavorite(_ photo: Photo) async throws
    func removeFavorite(photoId: String) async throws
}

enum FavoriteRepositoryError: Error {
    case notFound
    case saveFailed
    case deleteFailed
    case fetchFailed
}

/// SwiftData implementation of FavoriteRepository
/// Uses ModelContext for CRUD operations on FavoritePhotoEntity
final class DefaultFavoriteRepository: FavoriteRepository {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    @MainActor
    func getFavorites() async throws -> [Photo] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<FavoritePhotoEntity>(
            sortBy: [SortDescriptor(\.favoritedAt, order: .reverse)]
        )

        do {
            let favorites = try context.fetch(descriptor)
            return favorites.map { $0.toPhoto() }
        } catch {
            throw FavoriteRepositoryError.fetchFailed
        }
    }

    @MainActor
    func isFavorite(photoId: String) async throws -> Bool {
        let context = modelContainer.mainContext
        let predicate = #Predicate<FavoritePhotoEntity> { entity in
            entity.id == photoId
        }

        let descriptor = FetchDescriptor<FavoritePhotoEntity>(
            predicate: predicate
        )

        do {
            let count = try context.fetchCount(descriptor)
            return count > 0
        } catch {
            throw FavoriteRepositoryError.fetchFailed
        }
    }

    @MainActor
    func addFavorite(_ photo: Photo) async throws {
        let context = modelContainer.mainContext

        // Check if already exists
        let exists = try await isFavorite(photoId: photo.id)
        guard !exists else { return }

        // Create and insert entity
        let entity = FavoritePhotoEntity.from(photo)
        context.insert(entity)

        do {
            try context.save()
        } catch {
            throw FavoriteRepositoryError.saveFailed
        }
    }

    @MainActor
    func removeFavorite(photoId: String) async throws {
        let context = modelContainer.mainContext

        // Find entity to delete
        let predicate = #Predicate<FavoritePhotoEntity> { entity in
            entity.id == photoId
        }

        let descriptor = FetchDescriptor<FavoritePhotoEntity>(
            predicate: predicate
        )

        do {
            let entities = try context.fetch(descriptor)
            guard let entity = entities.first else {
                throw FavoriteRepositoryError.notFound
            }

            context.delete(entity)
            try context.save()
        } catch is FavoriteRepositoryError {
            throw error
        } catch {
            throw FavoriteRepositoryError.deleteFailed
        }
    }
}
