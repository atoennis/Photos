// Data/Repositories/FavoriteRepository.swift
import Foundation
import SwiftData

/// Repository protocol for managing favorite photos
/// Follows Clean Architecture: protocol defined here, but referenced from Domain layer
protocol FavoriteRepository {
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
@ModelActor
actor DefaultFavoriteRepository: FavoriteRepository {
    func getFavorites() async throws -> [Photo] {
        let descriptor = FetchDescriptor<FavoritePhotoEntity>(
            sortBy: [SortDescriptor(\.favoritedAt, order: .reverse)]
        )

        do {
            let favorites = try modelContext.fetch(descriptor)
            return favorites.map { $0.toPhoto() }
        } catch {
            throw FavoriteRepositoryError.fetchFailed
        }
    }

    func isFavorite(photoId: String) async throws -> Bool {
        let predicate = #Predicate<FavoritePhotoEntity> { entity in
            entity.id == photoId
        }

        let descriptor = FetchDescriptor<FavoritePhotoEntity>(
            predicate: predicate
        )

        do {
            let count = try modelContext.fetchCount(descriptor)
            return count > 0
        } catch {
            throw FavoriteRepositoryError.fetchFailed
        }
    }

    func addFavorite(_ photo: Photo) async throws {
        // Check if already exists
        let exists = try await isFavorite(photoId: photo.id)
        guard !exists else { return }

        // Create and insert entity
        let entity = FavoritePhotoEntity.from(photo)
        modelContext.insert(entity)

        do {
            try modelContext.save()
        } catch {
            throw FavoriteRepositoryError.saveFailed
        }
    }

    func removeFavorite(photoId: String) async throws {
        // Find entity to delete
        let predicate = #Predicate<FavoritePhotoEntity> { entity in
            entity.id == photoId
        }

        let descriptor = FetchDescriptor<FavoritePhotoEntity>(
            predicate: predicate
        )

        do {
            let entities = try modelContext.fetch(descriptor)
            guard let entity = entities.first else {
                throw FavoriteRepositoryError.notFound
            }

            modelContext.delete(entity)
            try modelContext.save()
        } catch let error as FavoriteRepositoryError {
            throw error
        } catch {
            throw FavoriteRepositoryError.deleteFailed
        }
    }
}
