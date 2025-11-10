// Domain/UseCases/PhotoUseCase.swift
import Foundation

protocol HasPhotoUseCase {
    var photoUseCase: PhotoUseCase { get }
}

protocol PhotoUseCase {
    func fetchPhotoDetail(id: String) async throws -> Photo
    func fetchPhotos() async throws -> [Photo]
}

struct DefaultPhotoUseCase: PhotoUseCase {
    let repository: PhotoRepository

    func fetchPhotoDetail(id: String) async throws -> Photo {
        try await repository.fetchPhotoDetail(id: id)
    }

    func fetchPhotos() async throws -> [Photo] {
        try await repository.fetchPhotos()
    }
}
