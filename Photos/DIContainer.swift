import Foundation
import SwiftData

// Compose all use case protocols
typealias AllUseCases = HasPhotoUseCase
    & HasFavoriteUseCase

struct DIContainer: AllUseCases {
    var photoUseCase: PhotoUseCase
    var favoriteUseCase: FavoriteUseCase
    var viewModelFactory: ViewModelFactory
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
        var viewModelFactory = DefaultViewModelFactory()

        let container = DIContainer(
            photoUseCase: photoUseCase,
            favoriteUseCase: favoriteUseCase,
            viewModelFactory: viewModelFactory
        )

        viewModelFactory.useCases = container

        return container
    }

    // Mock configuration for tests/previews
    static func mock(
        photoUseCase: PhotoUseCase = MockPhotoUseCase(),
        favoriteUseCase: FavoriteUseCase = MockFavoriteUseCase()
    ) -> DIContainer {
        var factory = DefaultViewModelFactory()
        let container = DIContainer(
            photoUseCase: photoUseCase,
            favoriteUseCase: favoriteUseCase,
            viewModelFactory: factory
        )
        factory.useCases = container

        return container
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
