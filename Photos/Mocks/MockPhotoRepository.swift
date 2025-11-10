// Mocks/MockPhotoRepository.swift
#if DEBUG
import Foundation

struct MockPhotoRepository: PhotoRepository {
    var delay: TimeInterval? = nil
    var photo: Photo? = nil
    var photos: [Photo] = .fixtures
    var throwError: Bool = false

    func fetchPhotoDetail(id: String) async throws -> Photo {
        if let delay {
            try await Task.sleep(for: .seconds(delay))
        }
        guard !throwError else {
            throw MockError.mockError
        }
        if let photo {
            return photo
        }
        // Return first fixture that matches ID, or first fixture if no match
        return photos.first(where: { $0.id == id }) ?? photos[0]
    }

    func fetchPhotos() async throws -> [Photo] {
        if let delay {
            try await Task.sleep(for: .seconds(delay))
        }
        guard !throwError else {
            throw MockError.mockError
        }
        return photos
    }
}
#endif
