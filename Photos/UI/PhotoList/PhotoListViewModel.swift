// UI/PhotoList/PhotoListViewModel.swift
import Foundation

@Observable
@MainActor
class PhotoListViewModel {
    // MVI Pattern: Actions represent user intents
    enum Action {
        case onAppear
        case refreshPulled
        case retry
    }

    // State is equatable for testability
    struct State: Equatable {
        var errorLoading: Bool = false
        var isLoading: Bool = false
        var photos: [Photo] = []

        // Derived state as computed properties
        var isEmpty: Bool { photos.isEmpty && !isLoading }
    }

    // Dependencies typed by protocol composition
    typealias UseCases = HasPhotoUseCase
    let useCases: UseCases
    var state: State

    init(state: State, useCases: UseCases) {
        self.useCases = useCases
        self.state = state
    }

    // Unidirectional data flow
    func send(_ action: Action) async {
        switch action {
        case .onAppear, .retry:
            await fetchPhotos(showLoading: true)
        case .refreshPulled:
            await fetchPhotos(showLoading: false)
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
}
