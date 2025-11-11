// Domain/UseCases/ViewModelFactory.swift
import Foundation

/// Factory protocol for creating ViewModels with appropriate dependencies
/// This allows Views to create child ViewModels without ViewModels needing all use cases
/// Protocol lives in Domain layer as it's about providing business logic with dependencies
protocol ViewModelFactory: Sendable {
    @MainActor
    func makePhotoDetailViewModel(photoId: String) -> PhotoDetailViewModel
}

struct DefaultViewModelFactory: ViewModelFactory {
    var useCases: AllUseCases? = nil

    func makePhotoDetailViewModel(photoId: String) -> PhotoDetailViewModel {
        guard let useCases else { fatalError("UseCases have not been initialized") }

        return PhotoDetailViewModel(
            photoId: photoId,
            useCases: useCases
        )
    }
}
