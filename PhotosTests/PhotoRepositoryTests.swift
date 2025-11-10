// PhotoRepositoryTests.swift
import Testing
import Foundation
@testable import Photos

struct PhotoRepositoryTests {

    @Test func fetchPhotosSuccess() async throws {
        let mockSession = try MockNetworkSession(response: [PhotoJSON].fixtures)
        let repository = DefaultPhotoRepository(
            session: mockSession,
            environment: .production
        )

        let photos = try await repository.fetchPhotos()

        #expect(!photos.isEmpty)
        #expect(photos.count == 5)
        #expect(photos[0].id == "0")
        #expect(photos[0].author == "Alejandro Escamilla")
    }

    @Test func fetchPhotosNetworkError() async {
        let mockSession = MockNetworkSession(throwError: true)
        let repository = DefaultPhotoRepository(
            session: mockSession,
            environment: .production
        )

        await #expect(throws: URLError.self) {
            try await repository.fetchPhotos()
        }
    }

    @Test func fetchPhotosInvalidStatusCode() async throws {
        let mockSession = try MockNetworkSession(
            statusCode: 404,
            response: [PhotoJSON].fixtures
        )
        let repository = DefaultPhotoRepository(
            session: mockSession,
            environment: .production
        )

        await #expect(throws: PhotoRepositoryError.self) {
            try await repository.fetchPhotos()
        }
    }

    @Test func fetchPhotosValidatesHTTPResponse() async throws {
        let mockSession = try MockNetworkSession(
            statusCode: 500,
            response: [PhotoJSON].fixtures
        )
        let repository = DefaultPhotoRepository(
            session: mockSession,
            environment: .production
        )

        await #expect(throws: PhotoRepositoryError.self) {
            try await repository.fetchPhotos()
        }
    }

    @Test func fetchPhotosDecodingError() async {
        let invalidJSON = "{ invalid json }".data(using: .utf8)!
        let mockSession = MockNetworkSession(responseData: invalidJSON)
        let repository = DefaultPhotoRepository(
            session: mockSession,
            environment: .production
        )

        await #expect(throws: PhotoRepositoryError.self) {
            try await repository.fetchPhotos()
        }
    }

    @Test func fetchPhotosEmptyArray() async throws {
        let mockSession = try MockNetworkSession(response: [PhotoJSON]())
        let repository = DefaultPhotoRepository(
            session: mockSession,
            environment: .production
        )

        let photos = try await repository.fetchPhotos()

        #expect(photos.isEmpty)
    }
}
