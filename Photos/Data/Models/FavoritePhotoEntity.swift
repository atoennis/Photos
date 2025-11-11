// Data/Models/FavoritePhotoEntity.swift
import SwiftData
import Foundation

/// SwiftData entity for persisting favorite photos
/// Maps to the Photo domain model
@Model
final class FavoritePhotoEntity {
    @Attribute(.unique) var id: String
    var author: String
    var downloadUrl: String
    var height: Int
    var url: String
    var width: Int
    var favoritedAt: Date

    init(
        author: String,
        downloadUrl: String,
        favoritedAt: Date = Date(),
        height: Int,
        id: String,
        url: String,
        width: Int
    ) {
        self.id = id
        self.author = author
        self.downloadUrl = downloadUrl
        self.height = height
        self.url = url
        self.width = width
        self.favoritedAt = favoritedAt
    }
}

// MARK: - Mapping Extensions

extension FavoritePhotoEntity {
    /// Convert SwiftData entity to domain model
    func toPhoto() -> Photo {
        Photo(
            author: author,
            downloadUrl: downloadUrl,
            height: height,
            id: id,
            url: url,
            width: width
        )
    }

    /// Create SwiftData entity from domain model
    static func from(_ photo: Photo) -> FavoritePhotoEntity {
        FavoritePhotoEntity(
            author: photo.author,
            downloadUrl: photo.downloadUrl,
            height: photo.height,
            id: photo.id,
            url: photo.url,
            width: photo.width
        )
    }
}
