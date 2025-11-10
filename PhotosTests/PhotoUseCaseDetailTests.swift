// PhotoUseCaseDetailTests.swift
import Testing
import Foundation
@testable import Photos

struct PhotoUseCaseDetailTests {

    @Test func fetchPhotoDetailSuccess() async throws {
        let expectedPhoto = Photo.fixture(id: "42")
        let mockRepository = MockPhotoRepository(
            photo: expectedPhoto,
            throwError: false
        )
        let useCase = DefaultPhotoUseCase(repository: mockRepository)

        let photo = try await useCase.fetchPhotoDetail(id: "42")

        #expect(photo.id == "42")
        #expect(photo == expectedPhoto)
    }

    @Test func fetchPhotoDetailError() async {
        let mockRepository = MockPhotoRepository(throwError: true)
        let useCase = DefaultPhotoUseCase(repository: mockRepository)

        await #expect(throws: MockError.self) {
            try await useCase.fetchPhotoDetail(id: "1")
        }
    }

    @Test func fetchPhotoDetailPropagatesRepositoryData() async throws {
        let customPhoto = Photo.fixture(
            author: "Custom Author",
            height: 2000,
            id: "999",
            width: 3000
        )
        let mockRepository = MockPhotoRepository(
            photo: customPhoto,
            throwError: false
        )
        let useCase = DefaultPhotoUseCase(repository: mockRepository)

        let photo = try await useCase.fetchPhotoDetail(id: "999")

        #expect(photo.id == "999")
        #expect(photo.author == "Custom Author")
        #expect(photo.width == 3000)
        #expect(photo.height == 2000)
    }

    @Test func fetchPhotoDetailWithDifferentIds() async throws {
        let photo1 = Photo.fixture(id: "1")
        let photo10 = Photo.fixture(id: "10")
        let photos = [photo1, photo10]
        let mockRepository = MockPhotoRepository(
            photos: photos,
            throwError: false
        )
        let useCase = DefaultPhotoUseCase(repository: mockRepository)

        let result1 = try await useCase.fetchPhotoDetail(id: "1")
        let result10 = try await useCase.fetchPhotoDetail(id: "10")

        #expect(result1.id == "1")
        #expect(result10.id == "10")
    }
}
