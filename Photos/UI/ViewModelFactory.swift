// UI/ViewModelFactory.swift
import Foundation

/// Factory protocol for creating ViewModels with appropriate dependencies
/// Lives in UI layer as it's responsible for UI object creation
protocol ViewModelFactory: Sendable {
    @MainActor
    func makePhotoDetailViewModel(photoId: String) -> PhotoDetailViewModel
}
