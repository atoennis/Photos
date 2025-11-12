import Foundation
import SwiftData
import Nuke

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
        // Configure infrastructure
        configureImagePipeline()

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

    /// Configures Nuke's image pipeline with HTTP-based caching
    private static func configureImagePipeline() {
        let pipeline = ImagePipeline {
            // Use HTTP cache policy - respect cache-control headers
            $0.dataLoader = DataLoader(configuration: {
                let config = DataLoader.defaultConfiguration
                config.urlCache = URLCache(
                    memoryCapacity: 100 * 1024 * 1024,  // 100 MB memory cache
                    diskCapacity: 200 * 1024 * 1024     // 200 MB disk cache
                )
                // Respect HTTP caching headers
                config.requestCachePolicy = .returnCacheDataElseLoad
                return config
            }())

            // Configure image cache (decoded images)
            $0.imageCache = ImageCache(
                costLimit: 100 * 1024 * 1024,  // 100 MB memory limit
                countLimit: 100                 // Max 100 images in memory
            )

            // Enable aggressive disk caching
            $0.dataCache = try? DataCache(name: "com.adamtoennis.Photos.cache")

            // Disable rate limiter for faster loading
            $0.isRateLimiterEnabled = false
        }

        ImagePipeline.shared = pipeline
    }

    // Mock configuration for tests/previews
    static func mock(
        favoriteUseCase: FavoriteUseCase = MockFavoriteUseCase(),
        photoUseCase: PhotoUseCase = MockPhotoUseCase()
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
