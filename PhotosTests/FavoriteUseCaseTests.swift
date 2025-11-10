// FavoriteUseCaseTests.swift
import Testing
import Foundation
@testable import Photos

struct FavoriteUseCaseTests {

    @Test func getFavoritesSuccess() async throws {
        let mockRepository = MockFavoriteRepository(
            favorites: .fixtures,
            throwError: false
        )
        let useCase = DefaultFavoriteUseCase(repository: mockRepository)

        let favorites = try await useCase.getFavorites()

        #expect(favorites.count == 5)
        #expect(favorites == .fixtures)
    }

    @Test func getFavoritesError() async {
        let mockRepository = MockFavoriteRepository(throwError: true)
        let useCase = DefaultFavoriteUseCase(repository: mockRepository)

        await #expect(throws: MockError.self) {
            try await useCase.getFavorites()
        }
    }

    @Test func getFavoritesEmptyList() async throws {
        let mockRepository = MockFavoriteRepository(
            favorites: [],
            throwError: false
        )
        let useCase = DefaultFavoriteUseCase(repository: mockRepository)

        let favorites = try await useCase.getFavorites()

        #expect(favorites.isEmpty)
    }

    @Test func isFavoriteTrue() async throws {
        let photo = Photo.fixture(id: "1")
        let mockRepository = MockFavoriteRepository(
            favorites: [photo],
            throwError: false
        )
        let useCase = DefaultFavoriteUseCase(repository: mockRepository)

        let isFavorite = try await useCase.isFavorite(photoId: "1")

        #expect(isFavorite == true)
    }

    @Test func isFavoriteFalse() async throws {
        let mockRepository = MockFavoriteRepository(
            favorites: [],
            throwError: false
        )
        let useCase = DefaultFavoriteUseCase(repository: mockRepository)

        let isFavorite = try await useCase.isFavorite(photoId: "1")

        #expect(isFavorite == false)
    }

    @Test func isFavoriteError() async {
        let mockRepository = MockFavoriteRepository(throwError: true)
        let useCase = DefaultFavoriteUseCase(repository: mockRepository)

        await #expect(throws: MockError.self) {
            try await useCase.isFavorite(photoId: "1")
        }
    }

    @Test func toggleFavoriteSuccess() async throws {
        let photo = Photo.fixture(id: "1")
        let mockRepository = MockFavoriteRepository(
            favorites: [],
            throwError: false
        )
        let useCase = DefaultFavoriteUseCase(repository: mockRepository)

        // Should not throw
        try await useCase.toggleFavorite(photo)
    }

    @Test func toggleFavoriteError() async {
        let photo = Photo.fixture(id: "1")
        let mockRepository = MockFavoriteRepository(throwError: true)
        let useCase = DefaultFavoriteUseCase(repository: mockRepository)

        await #expect(throws: MockError.self) {
            try await useCase.toggleFavorite(photo)
        }
    }
}
