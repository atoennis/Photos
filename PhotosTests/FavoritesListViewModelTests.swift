// FavoritesListViewModelTests.swift
import Testing
import Foundation
@testable import Photos

@MainActor
struct FavoritesListViewModelTests {

    // MARK: - Mock Dependencies

    struct MockUseCases: HasFavoriteUseCase {
        var favoriteUseCase: FavoriteUseCase
    }

    // MARK: - Initial State Tests

    @Test func initialState() {
        let mockUseCase = MockFavoriteUseCase()
        let useCases = MockUseCases(favoriteUseCase: mockUseCase)
        let initialState = FavoritesListViewModel.State()
        let viewModel = FavoritesListViewModel(state: initialState, useCases: useCases)

        #expect(viewModel.state.favorites.isEmpty)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == false)
        #expect(viewModel.state.isEmpty == true)
    }

    // MARK: - Fetch Favorites Tests

    @Test func fetchFavoritesOnAppearSuccess() async {
        let mockUseCase = MockFavoriteUseCase(favorites: .fixtures, throwError: false)
        let useCases = MockUseCases(favoriteUseCase: mockUseCase)
        let viewModel = FavoritesListViewModel(
            state: FavoritesListViewModel.State(),
            useCases: useCases
        )

        await viewModel.send(.onAppear)

        #expect(viewModel.state.favorites.count == 5)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == false)
        #expect(viewModel.state.isEmpty == false)
    }

    @Test func fetchFavoritesOnAppearError() async {
        let mockUseCase = MockFavoriteUseCase(throwError: true)
        let useCases = MockUseCases(favoriteUseCase: mockUseCase)
        let viewModel = FavoritesListViewModel(
            state: FavoritesListViewModel.State(),
            useCases: useCases
        )

        await viewModel.send(.onAppear)

        #expect(viewModel.state.favorites.isEmpty)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == true)
        #expect(viewModel.state.isEmpty == true)
    }

    @Test func fetchFavoritesRefreshPulledSuccess() async {
        let mockUseCase = MockFavoriteUseCase(favorites: .fixtures, throwError: false)
        let useCases = MockUseCases(favoriteUseCase: mockUseCase)
        let initialFavorites = [Photo.fixture(id: "old")]
        let viewModel = FavoritesListViewModel(
            state: FavoritesListViewModel.State(favorites: initialFavorites),
            useCases: useCases
        )

        await viewModel.send(.refreshPulled)

        #expect(viewModel.state.favorites.count == 5)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == false)
    }

    @Test func fetchFavoritesRefreshPulledDoesNotShowLoading() async {
        let mockUseCase = MockFavoriteUseCase(delay: 0.1, favorites: .fixtures)
        let useCases = MockUseCases(favoriteUseCase: mockUseCase)
        let viewModel = FavoritesListViewModel(
            state: FavoritesListViewModel.State(),
            useCases: useCases
        )

        // Start refresh (which doesn't show loading)
        let task = Task {
            await viewModel.send(.refreshPulled)
        }

        // Check immediately that loading is false
        #expect(viewModel.state.isLoading == false)

        await task.value
    }

    // MARK: - State Transition Tests

    @Test func errorStateReset() async {
        let mockUseCase = MockFavoriteUseCase(favorites: .fixtures, throwError: false)
        let useCases = MockUseCases(favoriteUseCase: mockUseCase)
        let viewModel = FavoritesListViewModel(
            state: FavoritesListViewModel.State(errorLoading: true),
            useCases: useCases
        )

        await viewModel.send(.onAppear)

        #expect(viewModel.state.errorLoading == false)
    }

    @Test func isEmpty() {
        let mockUseCase = MockFavoriteUseCase()
        let useCases = MockUseCases(favoriteUseCase: mockUseCase)

        // Empty state
        var state = FavoritesListViewModel.State(isLoading: false, favorites: [])
        #expect(state.isEmpty == true)

        // Loading state
        state = FavoritesListViewModel.State(isLoading: true, favorites: [])
        #expect(state.isEmpty == false)

        // Has favorites
        state = FavoritesListViewModel.State(isLoading: false, favorites: .fixtures)
        #expect(state.isEmpty == false)
    }

    // MARK: - Multiple Action Tests

    @Test func multipleActionsInSequence() async {
        let mockUseCase = MockFavoriteUseCase(favorites: .fixtures, throwError: false)
        let useCases = MockUseCases(favoriteUseCase: mockUseCase)
        let viewModel = FavoritesListViewModel(
            state: FavoritesListViewModel.State(),
            useCases: useCases
        )

        // First load
        await viewModel.send(.onAppear)
        #expect(viewModel.state.favorites.count == 5)

        // Refresh
        await viewModel.send(.refreshPulled)
        #expect(viewModel.state.favorites.count == 5)
    }

    @Test func recoverFromError() async {
        let mockUseCase = MockFavoriteUseCase(throwError: true)
        let useCases = MockUseCases(favoriteUseCase: mockUseCase)
        let viewModel = FavoritesListViewModel(
            state: FavoritesListViewModel.State(),
            useCases: useCases
        )

        // Fail first
        await viewModel.send(.onAppear)
        #expect(viewModel.state.errorLoading == true)

        // Create new ViewModel with successful mock to test recovery
        let successfulUseCase = MockFavoriteUseCase(favorites: .fixtures, throwError: false)
        let successfulViewModel = FavoritesListViewModel(
            state: FavoritesListViewModel.State(),
            useCases: MockUseCases(favoriteUseCase: successfulUseCase)
        )

        // Retry and succeed
        await successfulViewModel.send(.onAppear)
        #expect(successfulViewModel.state.errorLoading == false)
        #expect(successfulViewModel.state.favorites.count == 5)
    }
}
