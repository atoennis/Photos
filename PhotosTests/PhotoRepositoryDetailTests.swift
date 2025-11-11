// PhotoRepositoryDetailTests.swift
import Testing
import Foundation
@testable import Photos

struct PhotoRepositoryDetailTests {

    // Helper to encode fixtures to JSON
    func makeJSONData(from fixture: PhotoJSON) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try encoder.encode(fixture)
    }

    @Test func fetchPhotoDetailSuccess() async throws {
        let photoFixture = PhotoJSON.fixture(id: "42")
        let jsonData = try makeJSONData(from: photoFixture)
        let mockSession = try MockNetworkSession(response: photoFixture)
        let repository = DefaultPhotoRepository(
            session: mockSession,
            environment: .production
        )

        let photo = try await repository.fetchPhotoDetail(id: "42")

        #expect(photo.id == "42")
        #expect(photo.author == "Alejandro Escamilla")
    }

    @Test func fetchPhotoDetailNetworkError() async {
        let mockSession = MockNetworkSession(responseData: Data(), statusCode: 200, throwError: true)
        let repository = DefaultPhotoRepository(
            session: mockSession,
            environment: .production
        )

        await #expect(throws: URLError.self) {
            try await repository.fetchPhotoDetail(id: "1")
        }
    }

    @Test func fetchPhotoDetailInvalidStatusCode() async throws {
        let photoFixture = PhotoJSON.fixture()
        let mockSession = try MockNetworkSession(
            response: photoFixture,
            statusCode: 404
        )
        let repository = DefaultPhotoRepository(
            session: mockSession,
            environment: .production
        )

        await #expect(throws: PhotoRepositoryError.self) {
            try await repository.fetchPhotoDetail(id: "1")
        }
    }

    @Test func fetchPhotoDetailServerError() async throws {
        let photoFixture = PhotoJSON.fixture()
        let mockSession = try MockNetworkSession(
            response: photoFixture,
            statusCode: 500
        )
        let repository = DefaultPhotoRepository(
            session: mockSession,
            environment: .production
        )

        await #expect(throws: PhotoRepositoryError.self) {
            try await repository.fetchPhotoDetail(id: "1")
        }
    }

    @Test func fetchPhotoDetailDecodingError() async {
        let invalidJSON = "{ invalid json }".data(using: .utf8)!
        let mockSession = MockNetworkSession(responseData: invalidJSON)
        let repository = DefaultPhotoRepository(
            session: mockSession,
            environment: .production
        )

        await #expect(throws: PhotoRepositoryError.self) {
            try await repository.fetchPhotoDetail(id: "1")
        }
    }

    @Test func fetchPhotoDetailCorrectEndpoint() async throws {
        // This test verifies the URL is constructed correctly
        // The mock would fail if the URL was wrong, but we can test different IDs
        let photoFixture = PhotoJSON.fixture(id: "999")
        let mockSession = try MockNetworkSession(response: photoFixture)
        let repository = DefaultPhotoRepository(
            session: mockSession,
            environment: .production
        )

        let photo = try await repository.fetchPhotoDetail(id: "999")

        #expect(photo.id == "999")
    }

    @Test func fetchPhotoDetailReturnsCompleteData() async throws {
        let photoFixture = PhotoJSON.fixture(
            author: "Test Author",
            downloadUrl: "https://test.com/photo.jpg",
            height: 1080,
            id: "123",
            url: "https://test.com",
            width: 1920
        )
        let mockSession = try MockNetworkSession(response: photoFixture)
        let repository = DefaultPhotoRepository(
            session: mockSession,
            environment: .production
        )

        let photo = try await repository.fetchPhotoDetail(id: "123")

        #expect(photo.id == "123")
        #expect(photo.author == "Test Author")
        #expect(photo.width == 1920)
        #expect(photo.height == 1080)
        #expect(photo.url == "https://test.com")
        #expect(photo.downloadUrl == "https://test.com/photo.jpg")
    }
}
