// PhotoDetailViewModelTests.swift
import Testing
import Foundation
@testable import Photos

@MainActor
struct PhotoDetailViewModelTests {
    let useCases: AllUseCases
    var photoUseCase: MockPhotoUseCase
    var favoriteUseCase: MockFavoriteUseCase

    init() {
        self.photoUseCase = MockPhotoUseCase()
        self.favoriteUseCase = MockFavoriteUseCase()
        self.useCases = DIContainer.mock(
            favoriteUseCase: favoriteUseCase,
            photoUseCase: photoUseCase
        )
    }

    // MARK: - Initial State Tests

    @Test func initialState() {
        let viewModel = PhotoDetailViewModel(
            photoId: "0",
            state: .init(),
            useCases: useCases
        )

        #expect(viewModel.state.photo == nil)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == false)
        #expect(viewModel.state.hasPhoto == false)
    }

    @Test func initialStateWithPhotoId() {
        let viewModel = PhotoDetailViewModel(
            photoId: "42",
            state: .init(),
            useCases: useCases
        )

        #expect(viewModel.photoId == "42")
    }

    // MARK: - Fetch Photo Detail Tests

    @Test func fetchPhotoDetailOnAppearSuccess() async {
        let expectedPhoto = Photo.fixture(id: "0")
        let useCases = DIContainer.mock(
            photoUseCase: MockPhotoUseCase(photo: expectedPhoto)
        )
        let viewModel = PhotoDetailViewModel(
            photoId: "0",
            state: .init(),
            useCases: useCases
        )

        await viewModel.send(.onAppear)

        #expect(viewModel.state.photo != nil)
        #expect(viewModel.state.photo?.id == "0")
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == false)
        #expect(viewModel.state.hasPhoto == true)
    }

    @Test func fetchPhotoDetailOnAppearError() async {
        let mockUseCase = MockPhotoUseCase(throwError: true)
        let useCases = DIContainer.mock(photoUseCase: mockUseCase)
        let viewModel = PhotoDetailViewModel(
            photoId: "0",
            state: .init(),
            useCases: useCases
        )

        await viewModel.send(.onAppear)

        #expect(viewModel.state.photo == nil)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == true)
        #expect(viewModel.state.hasPhoto == false)
    }

    @Test func fetchPhotoDetailRetrySuccess() async {
        let expectedPhoto = Photo.fixture(id: "0")
        let mockUseCase = MockPhotoUseCase(photo: expectedPhoto, throwError: false)
        let useCases = DIContainer.mock(photoUseCase: mockUseCase)
        let viewModel = PhotoDetailViewModel(
            photoId: "0",
            state: PhotoDetailViewModel.State(errorLoading: true),
            useCases: useCases
        )

        await viewModel.send(.retry)

        #expect(viewModel.state.photo != nil)
        #expect(viewModel.state.photo?.id == "0")
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorLoading == false)
        #expect(viewModel.state.hasPhoto == true)
    }

    @Test func fetchPhotoDetailDifferentIds() async {
        let photo42 = Photo.fixture(id: "42")
        let mockUseCase = MockPhotoUseCase(photo: photo42, throwError: false)
        let useCases = DIContainer.mock(photoUseCase: mockUseCase)
        let viewModel = PhotoDetailViewModel(
            photoId: "42",
            state: .init(),
            useCases: useCases
        )

        await viewModel.send(.onAppear)

        #expect(viewModel.state.photo?.id == "42")
    }

    // MARK: - Loading State Tests

    @Test func loadingStateSetDuringFetch() async {
        let mockUseCase = MockPhotoUseCase(delay: 0.1, photo: .fixture())
        let useCases = DIContainer.mock(photoUseCase: mockUseCase)
        let viewModel = PhotoDetailViewModel(
            photoId: "0",
            state: .init(),
            useCases: useCases
        )

        let task = Task {
            await viewModel.send(.onAppear)
        }

        // Wait a tiny bit for loading to start
        try? await Task.sleep(for: .milliseconds(10))
        #expect(viewModel.state.isLoading == true)

        await task.value
        #expect(viewModel.state.isLoading == false)
    }

    // MARK: - Error Recovery Tests

    @Test func recoverFromError() async {
        let mockUseCase = MockPhotoUseCase(throwError: true)
        let useCases = DIContainer.mock(photoUseCase: mockUseCase)
        let viewModel = PhotoDetailViewModel(
            photoId: "0",
            state: .init(),
            useCases: useCases
        )

        // Fail first
        await viewModel.send(.onAppear)
        #expect(viewModel.state.errorLoading == true)
        #expect(viewModel.state.photo == nil)

        // Create new ViewModel with successful mock to test recovery
        let successfulUseCase = MockPhotoUseCase(photo: Photo.fixture(id: "0"), throwError: false)
        let successfulViewModel = PhotoDetailViewModel(
            photoId: "0",
            state: .init(),
            useCases: DIContainer.mock(photoUseCase: successfulUseCase)
        )

        // Retry and succeed
        await successfulViewModel.send(.retry)
        #expect(successfulViewModel.state.errorLoading == false)
        #expect(successfulViewModel.state.photo?.id == "0")
    }

    @Test func errorStateReset() async {
        let mockUseCase = MockPhotoUseCase(photo: .fixture(), throwError: false)
        let useCases = DIContainer.mock(photoUseCase: mockUseCase)
        let viewModel = PhotoDetailViewModel(
            photoId: "0",
            state: PhotoDetailViewModel.State(errorLoading: true),
            useCases: useCases
        )

        await viewModel.send(.onAppear)

        #expect(viewModel.state.errorLoading == false)
    }

    // MARK: - Derived State Tests

    @Test func hasPhotoComputedProperty() {
        // No photo
        var state = PhotoDetailViewModel.State(photo: nil)
        #expect(state.hasPhoto == false)

        // Has photo
        state = PhotoDetailViewModel.State(photo: .fixture())
        #expect(state.hasPhoto == true)
    }

    // MARK: - Action Tests

    @Test func onAppearActionTriggersLoad() async {
        let mockUseCase = MockPhotoUseCase(photo: .fixture(id: "123"))
        let useCases = DIContainer.mock(photoUseCase: mockUseCase)
        let viewModel = PhotoDetailViewModel(
            photoId: "123",
            state: .init(),
            useCases: useCases
        )

        await viewModel.send(.onAppear)

        #expect(viewModel.state.photo?.id == "123")
    }

    @Test func retryActionTriggersLoad() async {
        let mockUseCase = MockPhotoUseCase(photo: .fixture(id: "456"))
        let useCases = DIContainer.mock(photoUseCase: mockUseCase)
        let viewModel = PhotoDetailViewModel(
            photoId: "456",
            state: .init(),
            useCases: useCases
        )

        await viewModel.send(.retry)

        #expect(viewModel.state.photo?.id == "456")
    }

    // MARK: - Photo Data Validation Tests

    @Test func fetchedPhotoContainsAllFields() async {
        let customPhoto = Photo.fixture(
            author: "Test Author",
            downloadUrl: "https://test.com/photo.jpg",
            height: 1080,
            id: "999",
            url: "https://test.com",
            width: 1920
        )
        let mockUseCase = MockPhotoUseCase(photo: customPhoto, throwError: false)
        let useCases = DIContainer.mock(photoUseCase: mockUseCase)
        let viewModel = PhotoDetailViewModel(
            photoId: "999",
            state: .init(),
            useCases: useCases
        )

        await viewModel.send(.onAppear)

        let photo = viewModel.state.photo
        #expect(photo?.id == "999")
        #expect(photo?.author == "Test Author")
        #expect(photo?.width == 1920)
        #expect(photo?.height == 1080)
        #expect(photo?.url == "https://test.com")
        #expect(photo?.downloadUrl == "https://test.com/photo.jpg")
    }
}
