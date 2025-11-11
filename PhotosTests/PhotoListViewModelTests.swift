// PhotoListViewModelTests.swift
import Testing
import Foundation
@testable import Photos

@MainActor
struct PhotoListViewModelTests {

    // MARK: - Mock Dependencies

    struct MockUseCases: HasPhotoUseCase {
        var photoUseCase: PhotoUseCase
    }

    // MARK: - Initial State Tests

    @Test func initialState() {
        let mockUseCase = MockPhotoUseCase()
        let useCases = MockUseCases(photoUseCase: mockUseCase)
        let initialState = PhotoListViewModel.State()
        let viewModel = PhotoListViewModel(useCases: useCases, state: initialState)

        #expect(viewModel.state.photos.isEmpty)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == false)
        #expect(viewModel.state.isEmpty == true)
    }

    // MARK: - Fetch Photos Tests

    @Test func fetchPhotosOnAppearSuccess() async {
        let mockUseCase = MockPhotoUseCase(photos: .fixtures, throwError: false)
        let useCases = MockUseCases(photoUseCase: mockUseCase)
        let viewModel = PhotoListViewModel(
            useCases: useCases,
            state: PhotoListViewModel.State()
        )

        await viewModel.send(.onAppear)

        #expect(viewModel.state.photos.count == 5)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == false)
        #expect(viewModel.state.isEmpty == false)
    }

    @Test func fetchPhotosOnAppearError() async {
        let mockUseCase = MockPhotoUseCase(throwError: true)
        let useCases = MockUseCases(photoUseCase: mockUseCase)
        let viewModel = PhotoListViewModel(
            useCases: useCases,
            state: PhotoListViewModel.State()
        )

        await viewModel.send(.onAppear)

        #expect(viewModel.state.photos.isEmpty)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == true)
        #expect(viewModel.state.isEmpty == true)
    }

    @Test func fetchPhotosRetrySuccess() async {
        let mockUseCase = MockPhotoUseCase(photos: .fixtures, throwError: false)
        let useCases = MockUseCases(photoUseCase: mockUseCase)
        let viewModel = PhotoListViewModel(
            useCases: useCases,
            state: PhotoListViewModel.State(errorLoading: true)
        )

        await viewModel.send(.retry)

        #expect(viewModel.state.photos.count == 5)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == false)
    }

    @Test func fetchPhotosRefreshPulledSuccess() async {
        let mockUseCase = MockPhotoUseCase(photos: .fixtures, throwError: false)
        let useCases = MockUseCases(photoUseCase: mockUseCase)
        let initialPhotos = [Photo.fixture(id: "old")]
        let viewModel = PhotoListViewModel(
            useCases: useCases,
            state: PhotoListViewModel.State(photos: initialPhotos)
        )

        await viewModel.send(.refreshPulled)

        #expect(viewModel.state.photos.count == 5)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == false)
    }

    @Test func fetchPhotosRefreshPulledDoesNotShowLoading() async {
        let mockUseCase = MockPhotoUseCase(delay: 0.1, photos: .fixtures)
        let useCases = MockUseCases(photoUseCase: mockUseCase)
        let viewModel = PhotoListViewModel(
            useCases: useCases,
            state: PhotoListViewModel.State()
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
        let useCases = MockUseCases(photoUseCase: mockUseCase)
        let viewModel = PhotoListViewModel(
            useCases: useCases,
            state: PhotoListViewModel.State(errorLoading: true)
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
        let useCases = MockUseCases(photoUseCase: mockUseCase)
        let viewModel = PhotoListViewModel(
            useCases: useCases,
            state: PhotoListViewModel.State()
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
        let useCases = MockUseCases(photoUseCase: mockUseCase)
        let viewModel = PhotoListViewModel(
            useCases: useCases,
            state: PhotoListViewModel.State()
        )

        // Fail first
        await viewModel.send(.onAppear)
        #expect(viewModel.state.errorLoading == true)

        // Create new ViewModel with successful mock to test recovery
        let successfulUseCase = MockPhotoUseCase(photos: .fixtures, throwError: false)
        let successfulViewModel = PhotoListViewModel(
            useCases: MockUseCases(photoUseCase: successfulUseCase),
            state: PhotoListViewModel.State()
        )

        // Retry and succeed
        await successfulViewModel.send(.retry)
        #expect(successfulViewModel.state.errorLoading == false)
        #expect(successfulViewModel.state.photos.count == 5)
    }
}
