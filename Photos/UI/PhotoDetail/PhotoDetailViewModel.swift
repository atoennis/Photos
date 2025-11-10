// UI/PhotoDetail/PhotoDetailViewModel.swift
import Foundation

@Observable
@MainActor
class PhotoDetailViewModel {
    // MVI Pattern: Actions represent user intents
    enum Action {
        case onAppear
        case retry
    }

    // State is equatable for testability
    struct State: Equatable {
        var errorLoading: Bool = false
        var isLoading: Bool = false
        var photo: Photo? = nil

        // Derived state as computed properties
        var hasPhoto: Bool { photo != nil }
    }

    // Dependencies typed by protocol composition
    typealias UseCases = HasPhotoUseCase
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
        case .onAppear, .retry:
            await fetchPhotoDetail()
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
}
