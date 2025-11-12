// UI/PhotoList/PhotoListViewModel.swift
import Foundation

@Observable
@MainActor
class PhotoListViewModel {
    // MVI Pattern: Actions represent user intents
    enum Action {
        case dismissError
        case onAppear
        case refreshPulled
        case retry
        case toggleFavorite(Photo)
    }

    // State is equatable for testability
    struct State: Equatable {
        var errorLoading: Bool = false
        var errorMessage: String? = nil
        var favoritePhotoIds: Set<String> = []
        var isLoading: Bool = false
        var photos: [Photo] = []

        // Derived state as computed properties
        var isEmpty: Bool { photos.isEmpty && !isLoading }

        func isFavorite(photoId: String) -> Bool {
            favoritePhotoIds.contains(photoId)
        }
    }

    // Dependencies typed by protocol composition
    typealias UseCases = HasPhotoUseCase & HasFavoriteUseCase
    let useCases: UseCases
    var state: State

    init(state: State, useCases: UseCases) {
        self.useCases = useCases
        self.state = state
    }

    // Unidirectional data flow
    func send(_ action: Action) async {
        switch action {
        case .dismissError:
            state.errorMessage = nil
        case .onAppear, .retry:
            await fetchPhotos(showLoading: true)
            await loadFavoriteStatus()
        case .refreshPulled:
            await fetchPhotos(showLoading: false)
            await loadFavoriteStatus()
        case .toggleFavorite(let photo):
            await toggleFavorite(photo)
        }
    }

    private func fetchPhotos(showLoading: Bool) async {
        if showLoading {
            state.isLoading = true
        }
        state.errorLoading = false

        do {
            state.photos = try await useCases.photoUseCase.fetchPhotos()
            state.errorLoading = false
        } catch {
            state.errorLoading = true
        }

        state.isLoading = false
    }

    private func loadFavoriteStatus() async {
        do {
            let favorites = try await useCases.favoriteUseCase.getFavorites()
            state.favoritePhotoIds = Set(favorites.map(\.id))
        } catch {
            // Silently fail - favorite status is not critical
            state.favoritePhotoIds = []
        }
    }

    private func toggleFavorite(_ photo: Photo) async {
        // Clear any previous error
        state.errorMessage = nil

        // Capture current state for rollback
        let wasOptimisticallyFavorited = state.favoritePhotoIds.contains(photo.id)

        // Optimistic update - instant UI feedback
        if wasOptimisticallyFavorited {
            state.favoritePhotoIds.remove(photo.id)
        } else {
            state.favoritePhotoIds.insert(photo.id)
        }

        // Persist change
        do {
            try await useCases.favoriteUseCase.toggleFavorite(photo)
        } catch {
            // Rollback on failure
            if wasOptimisticallyFavorited {
                state.favoritePhotoIds.insert(photo.id)
            } else {
                state.favoritePhotoIds.remove(photo.id)
            }

            // Set error message
            state.errorMessage = "Failed to update favorite"
        }
    }
}
