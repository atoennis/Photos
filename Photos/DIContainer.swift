import Foundation
import SwiftData

// Compose all use case protocols
typealias AllUseCases = HasPhotoUseCase & HasFavoriteUseCase

struct DIContainer: AllUseCases {
    var photoUseCase: PhotoUseCase
    var favoriteUseCase: FavoriteUseCase
}

// MARK: - ViewModelFactory Conformance
extension DIContainer: ViewModelFactory {
    @MainActor
    func makePhotoDetailViewModel(photoId: String) -> PhotoDetailViewModel {
        PhotoDetailViewModel(
            photoId: photoId,
            useCases: self
        )
    }
}

extension DIContainer {
    // Production configuration
    static func real(modelContainer: ModelContainer) -> DIContainer {
        // Build dependency graph from bottom up
        let networkSession = URLSession.shared
        let photoRepository = DefaultPhotoRepository(
            session: networkSession,
            environment: .production
        )
        let photoUseCase = DefaultPhotoUseCase(repository: photoRepository)

        let favoriteRepository = DefaultFavoriteRepository(modelContainer: modelContainer)
        let favoriteUseCase = DefaultFavoriteUseCase(repository: favoriteRepository)

        return DIContainer(
            photoUseCase: photoUseCase,
            favoriteUseCase: favoriteUseCase
        )
    }

    // Mock configuration for tests/previews
    static func mock(
        mockPhotoUseCase: PhotoUseCase? = nil,
        mockFavoriteUseCase: FavoriteUseCase? = nil
    ) -> DIContainer {
        DIContainer(
            photoUseCase: mockPhotoUseCase ?? MockPhotoUseCase(),
            favoriteUseCase: mockFavoriteUseCase ?? MockFavoriteUseCase()
        )
    }
}
