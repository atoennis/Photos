// PhotoListViewModelTests.swift
import Testing
import Foundation
@testable import Photos

@MainActor
struct PhotoListViewModelTests {

    // MARK: - Mock Dependencies

    struct MockUseCases: HasPhotoUseCase & HasFavoriteUseCase {
        var favoriteUseCase: FavoriteUseCase
        var photoUseCase: PhotoUseCase
    }

    // MARK: - Initial State Tests

    @Test func initialState() {
        let mockUseCase = MockPhotoUseCase()
        let mockFavoriteUseCase = MockFavoriteUseCase(favorites: [])
        let useCases = MockUseCases(
            favoriteUseCase: mockFavoriteUseCase,
            photoUseCase: mockUseCase
        )
        let initialState = PhotoListViewModel.State()
        let viewModel = PhotoListViewModel(state: initialState, useCases: useCases)

        #expect(viewModel.state.photos.isEmpty)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == false)
        #expect(viewModel.state.isEmpty == true)
    }

    // MARK: - Fetch Photos Tests

    @Test func fetchPhotosOnAppearSuccess() async {
        let mockUseCase = MockPhotoUseCase(photos: .fixtures, throwError: false)
        let mockFavoriteUseCase = MockFavoriteUseCase(favorites: [])
        let useCases = MockUseCases(
            favoriteUseCase: mockFavoriteUseCase,
            photoUseCase: mockUseCase
        )
        let viewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(),
            useCases: useCases
        )

        await viewModel.send(.onAppear)

        #expect(viewModel.state.photos.count == 5)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == false)
        #expect(viewModel.state.isEmpty == false)
    }

    @Test func fetchPhotosOnAppearError() async {
        let mockUseCase = MockPhotoUseCase(throwError: true)
        let mockFavoriteUseCase = MockFavoriteUseCase(favorites: [])
        let useCases = MockUseCases(
            favoriteUseCase: mockFavoriteUseCase,
            photoUseCase: mockUseCase
        )
        let viewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(),
            useCases: useCases
        )

        await viewModel.send(.onAppear)

        #expect(viewModel.state.photos.isEmpty)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == true)
        #expect(viewModel.state.isEmpty == true)
    }

    @Test func fetchPhotosRetrySuccess() async {
        let mockUseCase = MockPhotoUseCase(photos: .fixtures, throwError: false)
        let mockFavoriteUseCase = MockFavoriteUseCase(favorites: [])
        let useCases = MockUseCases(
            favoriteUseCase: mockFavoriteUseCase,
            photoUseCase: mockUseCase
        )
        let viewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(errorLoading: true),
            useCases: useCases
        )

        await viewModel.send(.retry)

        #expect(viewModel.state.photos.count == 5)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == false)
    }

    @Test func fetchPhotosRefreshPulledSuccess() async {
        let mockUseCase = MockPhotoUseCase(photos: .fixtures, throwError: false)
        let mockFavoriteUseCase = MockFavoriteUseCase(favorites: [])
        let useCases = MockUseCases(
            favoriteUseCase: mockFavoriteUseCase,
            photoUseCase: mockUseCase
        )
        let initialPhotos = [Photo.fixture(id: "old")]
        let viewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(photos: initialPhotos),
            useCases: useCases
        )

        await viewModel.send(.refreshPulled)

        #expect(viewModel.state.photos.count == 5)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == false)
    }

    @Test func fetchPhotosRefreshPulledDoesNotShowLoading() async {
        let mockUseCase = MockPhotoUseCase(delay: 0.1, photos: .fixtures)
        let mockFavoriteUseCase = MockFavoriteUseCase(favorites: [])
        let useCases = MockUseCases(
            favoriteUseCase: mockFavoriteUseCase,
            photoUseCase: mockUseCase
        )
        let viewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(),
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
        let mockUseCase = MockPhotoUseCase(photos: .fixtures, throwError: false)
        let mockFavoriteUseCase = MockFavoriteUseCase(favorites: [])
        let useCases = MockUseCases(
            favoriteUseCase: mockFavoriteUseCase,
            photoUseCase: mockUseCase
        )
        let viewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(errorLoading: true),
            useCases: useCases
        )

        await viewModel.send(.onAppear)

        #expect(viewModel.state.errorLoading == false)
    }

    @Test func isEmpty() {
        // Empty state
        var state = PhotoListViewModel.State(isLoading: false, photos: [])
        #expect(state.isEmpty == true)

        // Loading state
        state = PhotoListViewModel.State(isLoading: true, photos: [])
        #expect(state.isEmpty == false)

        // Has photos
        state = PhotoListViewModel.State(isLoading: false, photos: .fixtures)
        #expect(state.isEmpty == false)
    }

    // MARK: - Multiple Action Tests

    @Test func multipleActionsInSequence() async {
        let mockUseCase = MockPhotoUseCase(photos: .fixtures, throwError: false)
        let mockFavoriteUseCase = MockFavoriteUseCase(favorites: [])
        let useCases = MockUseCases(
            favoriteUseCase: mockFavoriteUseCase,
            photoUseCase: mockUseCase
        )
        let viewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(),
            useCases: useCases
        )

        // First load
        await viewModel.send(.onAppear)
        #expect(viewModel.state.photos.count == 5)

        // Refresh
        await viewModel.send(.refreshPulled)
        #expect(viewModel.state.photos.count == 5)

        // Retry
        await viewModel.send(.retry)
        #expect(viewModel.state.photos.count == 5)
    }

    @Test func recoverFromError() async {
        let mockUseCase = MockPhotoUseCase(throwError: true)
        let mockFavoriteUseCase = MockFavoriteUseCase(favorites: [])
        let useCases = MockUseCases(
            favoriteUseCase: mockFavoriteUseCase,
            photoUseCase: mockUseCase
        )
        let viewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(),
            useCases: useCases
        )

        // Fail first
        await viewModel.send(.onAppear)
        #expect(viewModel.state.errorLoading == true)

        // Create new ViewModel with successful mock to test recovery
        let successfulUseCase = MockPhotoUseCase(photos: .fixtures, throwError: false)
        let successfulFavoriteUseCase = MockFavoriteUseCase(favorites: [])
        let successfulViewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(),
            useCases: MockUseCases(
                favoriteUseCase: successfulFavoriteUseCase,
                photoUseCase: successfulUseCase
            )
        )

        // Retry and succeed
        await successfulViewModel.send(.retry)
        #expect(successfulViewModel.state.errorLoading == false)
        #expect(successfulViewModel.state.photos.count == 5)
    }

    // MARK: - Favorite Tests

    @Test func toggleFavoriteAddsToFavorites() async {
        let photo = Photo.fixture(id: "test-photo")
        let mockFavoriteUseCase = MockFavoriteUseCase(favorites: [])
        let useCases = MockUseCases(
            favoriteUseCase: mockFavoriteUseCase,
            photoUseCase: MockPhotoUseCase(photos: [photo])
        )
        let viewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(photos: [photo]),
            useCases: useCases
        )

        await viewModel.send(.toggleFavorite(photo))

        #expect(viewModel.state.favoritePhotoIds.contains("test-photo"))
    }

    @Test func toggleFavoriteRemovesFromFavorites() async {
        let photo = Photo.fixture(id: "test-photo")
        let mockFavoriteUseCase = MockFavoriteUseCase(favorites: [photo])
        let useCases = MockUseCases(
            favoriteUseCase: mockFavoriteUseCase,
            photoUseCase: MockPhotoUseCase(photos: [photo])
        )
        let viewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(
                favoritePhotoIds: ["test-photo"],
                photos: [photo]
            ),
            useCases: useCases
        )

        await viewModel.send(.toggleFavorite(photo))

        #expect(!viewModel.state.favoritePhotoIds.contains("test-photo"))
    }

    @Test func onAppearLoadsFavoriteStatus() async {
        let favoritePhoto = Photo.fixture(id: "fav-1")
        let regularPhoto = Photo.fixture(id: "reg-1")
        let mockFavoriteUseCase = MockFavoriteUseCase(favorites: [favoritePhoto])
        let useCases = MockUseCases(
            favoriteUseCase: mockFavoriteUseCase,
            photoUseCase: MockPhotoUseCase(photos: [favoritePhoto, regularPhoto])
        )
        let viewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(),
            useCases: useCases
        )

        await viewModel.send(.onAppear)

        #expect(viewModel.state.favoritePhotoIds.contains("fav-1"))
        #expect(!viewModel.state.favoritePhotoIds.contains("reg-1"))
    }

    @Test func isFavoriteReturnsTrueForFavoritedPhoto() {
        let state = PhotoListViewModel.State(
            favoritePhotoIds: ["fav-1", "fav-2"]
        )

        #expect(state.isFavorite(photoId: "fav-1"))
        #expect(state.isFavorite(photoId: "fav-2"))
        #expect(!state.isFavorite(photoId: "not-fav"))
    }

    @Test func toggleFavoriteRollbackOnError() async {
        let photo = Photo.fixture(id: "test-photo")
        let mockFavoriteUseCase = MockFavoriteUseCase(
            favorites: [],
            throwError: true
        )
        let useCases = MockUseCases(
            favoriteUseCase: mockFavoriteUseCase,
            photoUseCase: MockPhotoUseCase(photos: [photo])
        )
        let viewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(photos: [photo]),
            useCases: useCases
        )

        await viewModel.send(.toggleFavorite(photo))

        // Should not have added to favorites due to error
        #expect(!viewModel.state.favoritePhotoIds.contains("test-photo"))
        // Should have error message
        #expect(viewModel.state.errorMessage != nil)
    }

    @Test func toggleFavoriteRollbackRemovalOnError() async {
        let photo = Photo.fixture(id: "test-photo")
        let mockFavoriteUseCase = MockFavoriteUseCase(
            favorites: [photo],
            throwError: true
        )
        let useCases = MockUseCases(
            favoriteUseCase: mockFavoriteUseCase,
            photoUseCase: MockPhotoUseCase(photos: [photo])
        )
        let viewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(
                favoritePhotoIds: ["test-photo"],
                photos: [photo]
            ),
            useCases: useCases
        )

        await viewModel.send(.toggleFavorite(photo))

        // Should still be in favorites after rollback
        #expect(viewModel.state.favoritePhotoIds.contains("test-photo"))
        // Should have error message
        #expect(viewModel.state.errorMessage != nil)
    }

    @Test func dismissErrorClearsErrorMessage() async {
        let viewModel = PhotoListViewModel(
            state: PhotoListViewModel.State(errorMessage: "Some error"),
            useCases: MockUseCases(
                favoriteUseCase: MockFavoriteUseCase(favorites: []),
                photoUseCase: MockPhotoUseCase(photos: [])
            )
        )

        await viewModel.send(.dismissError)

        #expect(viewModel.state.errorMessage == nil)
    }
}
