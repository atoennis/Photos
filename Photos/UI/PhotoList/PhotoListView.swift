// UI/PhotoList/PhotoListView.swift
import SwiftUI
import NukeUI

struct PhotoListView: View {
    @State var viewModel: PhotoListViewModel
    @Environment(\.viewModelFactory) private var factory

    var body: some View {
        NavigationStack {
            content()
                .navigationTitle("Photos")
                .alert(
                    "Error Loading Photos",
                    isPresented: .constant(viewModel.state.errorLoading)
                ) {
                    Button(String(localized: "Common.Retry.label")) {
                        Task { await viewModel.send(.retry) }
                    }
                } message: {
                    Text("Unable to load photos. Please try again.")
                }
                .alert(
                    "Error",
                    isPresented: Binding(
                        get: { viewModel.state.errorMessage != nil },
                        set: { if !$0 { Task { await viewModel.send(.dismissError) } } }
                    )
                ) {
                    Button("OK", role: .cancel) {}
                } message: {
                    if let errorMessage = viewModel.state.errorMessage {
                        Text(errorMessage)
                    }
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
                "No Photos Yet",
                systemImage: "photo.fill",
                description: Text("Pull to refresh to load photos")
            )
        } else {
            List {
                ForEach(viewModel.state.photos) { photo in
                    NavigationLink(value: photo.id) {
                        PhotoRowView(
                            isFavorite: viewModel.state.isFavorite(photoId: photo.id),
                            photo: photo
                        ) {
                            Task {
                                await viewModel.send(.toggleFavorite(photo))
                            }
                        }
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

struct PhotoRowView: View {
    let isFavorite: Bool
    let photo: Photo
    let onToggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Display the photo using Nuke for caching
            LazyImage(url: URL(string: photo.downloadUrl)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if state.error != nil {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(photo.aspectRatio, contentMode: .fit)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(photo.aspectRatio, contentMode: .fit)
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topTrailing) {
                Button {
                    onToggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : .white)
                        .font(.title2)
                        .shadow(
                            color: .black.opacity(0.3),
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    isFavorite
                        ? String(localized: .photoListUnfavoriteButtonAccessibilityLabel)
                        : String(localized: .photoListFavoriteButtonAccessibilityLabel)
                )
                .padding(8)
            }

            // Photo info
            VStack(alignment: .leading, spacing: 4) {
                Text("By \(photo.author)")
                    .font(.headline)

                HStack {
                    Label(photo.displayInfo, systemImage: "aspectratio")
                    Spacer()
                    Text("ID: \(photo.id)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview("Loaded") {
    PhotoListView(
        viewModel: .init(
            state: .init(),
            useCases: DIContainer.mock(
                favoriteUseCase: MockFavoriteUseCase(favorites: [.fixture(id: "0")]),
                photoUseCase: MockPhotoUseCase(
                    photos: .fixtures
                )
            )
        )
    )
}

#Preview("Loading") {
    PhotoListView(
        viewModel: .init(
            state: .init(),
            useCases: DIContainer.mock(
                favoriteUseCase: MockFavoriteUseCase(favorites: []),
                photoUseCase: MockPhotoUseCase(
                    delay: 10,
                    photos: .fixtures
                )
            )
        )
    )
}

#Preview("Error") {
    PhotoListView(
        viewModel: .init(
            state: .init(),
            useCases: DIContainer.mock(
                favoriteUseCase: MockFavoriteUseCase(favorites: []),
                photoUseCase: MockPhotoUseCase(
                    throwError: true
                )
            )
        )
    )
}

#Preview("Empty") {
    PhotoListView(
        viewModel: .init(
            state: .init(),
            useCases: DIContainer.mock(
                favoriteUseCase: MockFavoriteUseCase(favorites: []),
                photoUseCase: MockPhotoUseCase(
                    photos: []
                )
            )
        )
    )
}
