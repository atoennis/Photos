// UI/Favorites/FavoritesListView.swift
import SwiftUI

struct FavoritesListView: View {
    @State var viewModel: FavoritesListViewModel
    @Environment(\.viewModelFactory) private var factory

    var body: some View {
        NavigationStack {
            content()
                .navigationTitle("Favorites")
                .alert(
                    "Error Loading Favorites",
                    isPresented: .constant(viewModel.state.errorLoading)
                ) {
                    Button(String(localized: "Common.Retry.label")) {
                        Task { await viewModel.send(.onAppear) }
                    }
                } message: {
                    Text("Unable to load favorites. Please try again.")
                }
                .overlay {
                    if viewModel.state.isLoading {
                        ProgressView()
                    }
                }
                .refreshable {
                    await viewModel.send(.refreshPulled)
                }
                .task {
                    await viewModel.send(.onAppear)
                }
        }
    }

    @ViewBuilder
    private func content() -> some View {
        if viewModel.state.isEmpty && !viewModel.state.errorLoading {
            ContentUnavailableView(
                "No Favorites Yet",
                systemImage: "heart.fill",
                description: Text("Favorite photos will appear here")
            )
        } else {
            List {
                ForEach(viewModel.state.favorites) { photo in
                    NavigationLink(value: photo.id) {
                        PhotoRowView(photo: photo)
                    }
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: String.self) { photoId in
                PhotoDetailView(
                    viewModel: factory.makePhotoDetailViewModel(photoId: photoId)
                )
            }
        }
    }
}

// MARK: - Previews

#Preview("Loaded") {
    FavoritesListView(
        viewModel: .init(
            useCases: DIContainer.mock(
                favoriteUseCase: MockFavoriteUseCase(
                    favorites: .fixtures
                )
            ),
            state: .init()
        )
    )
}

#Preview("Loading") {
    FavoritesListView(
        viewModel: .init(
            useCases: DIContainer.mock(
                favoriteUseCase: MockFavoriteUseCase(
                    delay: 10,
                    favorites: .fixtures
                )
            ),
            state: .init()
        )
    )
}

#Preview("Error") {
    FavoritesListView(
        viewModel: .init(
            useCases: DIContainer.mock(
                favoriteUseCase: MockFavoriteUseCase(
                    throwError: true
                )
            ),
            state: .init()
        )
    )
}

#Preview("Empty") {
    FavoritesListView(
        viewModel: .init(
            useCases: DIContainer.mock(
                favoriteUseCase: MockFavoriteUseCase(
                    favorites: []
                )
            ),
            state: .init()
        )
    )
}
