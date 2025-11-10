// PhotoUseCaseTests.swift
import Testing
import Foundation
@testable import Photos

struct PhotoUseCaseTests {

    @Test func fetchPhotosSuccess() async throws {
        let mockRepository = MockPhotoRepository(
            photos: .fixtures,
            throwError: false
        )
        let useCase = DefaultPhotoUseCase(repository: mockRepository)

        let photos = try await useCase.fetchPhotos()

        #expect(photos.count == 5)
        #expect(photos == .fixtures)
    }

    @Test func fetchPhotosError() async {
        let mockRepository = MockPhotoRepository(throwError: true)
        let useCase = DefaultPhotoUseCase(repository: mockRepository)

        await #expect(throws: MockError.self) {
            try await useCase.fetchPhotos()
        }
    }

    @Test func fetchPhotosEmptyList() async throws {
        let mockRepository = MockPhotoRepository(
            photos: [],
            throwError: false
        )
        let useCase = DefaultPhotoUseCase(repository: mockRepository)

        let photos = try await useCase.fetchPhotos()

        #expect(photos.isEmpty)
    }

    @Test func fetchPhotosCustomList() async throws {
        let customPhotos = [
            Photo.fixture(author: "Author 1", id: "1"),
            Photo.fixture(author: "Author 2", id: "2")
        ]
        let mockRepository = MockPhotoRepository(
            photos: customPhotos,
            throwError: false
        )
        let useCase = DefaultPhotoUseCase(repository: mockRepository)

        let photos = try await useCase.fetchPhotos()

        #expect(photos.count == 2)
        #expect(photos[0].id == "1")
        #expect(photos[1].id == "2")
    }
}
