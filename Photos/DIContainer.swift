import Foundation

// Compose all use case protocols
typealias AllUseCases = HasPhotoUseCase

struct DIContainer: AllUseCases {
    var photoUseCase: PhotoUseCase
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

        return DIContainer(
            photoUseCase: photoUseCase
        )
    }

    // Mock configuration for tests/previews
    static func mock(
        mockPhotoUseCase: PhotoUseCase? = nil
    ) -> DIContainer {
        DIContainer(
            photoUseCase: mockPhotoUseCase ?? MockPhotoUseCase()
        )
    }
}
