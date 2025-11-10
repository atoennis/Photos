// UI/PhotoDetail/PhotoDetailViewModel.swift
import Foundation

@Observable
@MainActor
class PhotoDetailViewModel {
    // MVI Pattern: Actions represent user intents
    enum Action {
        case onAppear
        case retry
        case toggleFavorite
    }

    // State is equatable for testability
    struct State: Equatable {
        var errorLoading: Bool = false
        var isLoading: Bool = false
        var photo: Photo? = nil
        var isFavorite: Bool = false

        // Derived state as computed properties
        var hasPhoto: Bool { photo != nil }
    }

    // Dependencies typed by protocol composition
    typealias UseCases = HasPhotoUseCase & HasFavoriteUseCase
    let photoId: String
    var state: State
    let useCases: UseCases

    init(photoId: String, useCases: UseCases, state: State = State()) {
        self.photoId = photoId
        self.useCases = useCases
        self.state = state
    }

    // Unidirectional data flow
    func send(_ action: Action) async {
        switch action {
        case .onAppear:
            await fetchPhotoDetail()
            await checkFavoriteStatus()
        case .retry:
            await fetchPhotoDetail()
        case .toggleFavorite:
            await toggleFavorite()
        }
    }

    private func fetchPhotoDetail() async {
        state.isLoading = true
        state.errorLoading = false

        do {
            state.photo = try await useCases.photoUseCase.fetchPhotoDetail(id: photoId)
            state.errorLoading = false
        } catch {
            state.errorLoading = true
        }

        state.isLoading = false
    }

    private func checkFavoriteStatus() async {
        do {
            state.isFavorite = try await useCases.favoriteUseCase.isFavorite(photoId: photoId)
        } catch {
            // Silently fail - favorite status is not critical
            state.isFavorite = false
        }
    }

    private func toggleFavorite() async {
        guard let photo = state.photo else { return }

        do {
            try await useCases.favoriteUseCase.toggleFavorite(photo)
            // Update local state after successful toggle
            state.isFavorite.toggle()
        } catch {
            // Could add error handling here if needed
        }
    }
}
