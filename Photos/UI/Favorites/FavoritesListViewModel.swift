// UI/Favorites/FavoritesListViewModel.swift
import Foundation

@Observable
@MainActor
class FavoritesListViewModel {
    // MVI Pattern: Actions represent user intents
    enum Action {
        case onAppear
        case refreshPulled
        case toggleFavorite(Photo)
    }

    // State is equatable for testability
    struct State: Equatable {
        var errorLoading: Bool = false
        var errorMessage: String? = nil
        var favorites: [Photo] = []
        var isLoading: Bool = false

        // Derived state as computed properties
        var isEmpty: Bool { favorites.isEmpty }
    }

    // Dependencies typed by protocol composition
    typealias UseCases = HasFavoriteUseCase
    let useCases: UseCases
    var state: State

    init(state: State = State(), useCases: UseCases) {
        self.useCases = useCases
        self.state = state
    }

    // Unidirectional data flow
    func send(_ action: Action) async {
        switch action {
        case .onAppear:
            await fetchFavorites(showLoading: true)
        case .refreshPulled:
            await fetchFavorites(showLoading: false)
        case .toggleFavorite(let photo):
            await toggleFavorite(photo)
        }
    }

    private func fetchFavorites(showLoading: Bool) async {
        if showLoading {
            state.isLoading = true
        }
        state.errorLoading = false

        do {
            state.favorites = try await useCases.favoriteUseCase.getFavorites()
            state.errorLoading = false
        } catch {
            state.errorLoading = true
        }

        state.isLoading = false
    }

    private func toggleFavorite(_ photo: Photo) async {
        // Clear any previous error
        state.errorMessage = nil

        // Capture current state for rollback
        let photoIndex = state.favorites.firstIndex(where: { $0.id == photo.id })

        // Optimistic update - instant UI feedback (remove from list)
        if let index = photoIndex {
            state.favorites.remove(at: index)
        }

        // Persist change
        do {
            try await useCases.favoriteUseCase.toggleFavorite(photo)
        } catch {
            // Rollback on failure (restore to list)
            if let index = photoIndex {
                state.favorites.insert(photo, at: index)
            }

            // Set error message
            state.errorMessage = "Failed to update favorite"
        }
    }
}
