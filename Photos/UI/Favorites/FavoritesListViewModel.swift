// UI/Favorites/FavoritesListViewModel.swift
import Foundation

@Observable
@MainActor
class FavoritesListViewModel {
    // MVI Pattern: Actions represent user intents
    enum Action {
        case onAppear
        case refreshPulled
    }

    // State is equatable for testability
    struct State: Equatable {
        var favorites: [Photo] = []
        var isLoading: Bool = false
        var errorLoading: Bool = false

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
}
