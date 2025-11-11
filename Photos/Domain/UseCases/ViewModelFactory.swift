// Domain/UseCases/ViewModelFactory.swift
import Foundation

/// Factory protocol for creating ViewModels with appropriate dependencies
/// This allows Views to create child ViewModels without ViewModels needing all use cases
/// Protocol lives in Domain layer as it's about providing business logic with dependencies
protocol ViewModelFactory: Sendable {
    @MainActor
    func makePhotoDetailViewModel(photoId: String) -> PhotoDetailViewModel
}
