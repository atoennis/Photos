import Foundation
import SwiftData

// Compose all use case protocols
typealias AllUseCases = HasPhotoUseCase
    & HasFavoriteUseCase

struct DIContainer: AllUseCases, ViewModelFactory {
    let photoUseCase: PhotoUseCase
    let favoriteUseCase: FavoriteUseCase

    // MARK: - ViewModelFactory

    @MainActor
    func makePhotoDetailViewModel(photoId: String) -> PhotoDetailViewModel {
        PhotoDetailViewModel(photoId: photoId, useCases: self)
    }
}

extension DIContainer {
    // Production configuration
    static func real() -> DIContainer {
        // Build dependency graph from bottom up
        let networkSession = URLSession.shared
        let photoRepository = DefaultPhotoRepository(
            session: networkSession,
            environment: .production
        )
        let photoUseCase = DefaultPhotoUseCase(repository: photoRepository)
        let favoriteRepository = DefaultFavoriteRepository(modelContainer: buildModelContainer())
        let favoriteUseCase = DefaultFavoriteUseCase(repository: favoriteRepository)

        return DIContainer(
            photoUseCase: photoUseCase,
            favoriteUseCase: favoriteUseCase
        )
    }

    // Mock configuration for tests/previews
    static func mock(
        photoUseCase: PhotoUseCase = MockPhotoUseCase(),
        favoriteUseCase: FavoriteUseCase = MockFavoriteUseCase()
    ) -> DIContainer {
        DIContainer(
            photoUseCase: photoUseCase,
            favoriteUseCase: favoriteUseCase
        )
    }
}

extension DIContainer {
    static func buildModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: FavoritePhotoEntity.self)
        } catch {
            fatalError("Unable to create ModelContainer") // TODO: Handle this more gracefully
        }
    }
}
