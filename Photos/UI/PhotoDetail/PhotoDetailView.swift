// UI/PhotoDetail/PhotoDetailView.swift
import SwiftUI
import NukeUI

struct PhotoDetailView: View {
    @State var viewModel: PhotoDetailViewModel

    var body: some View {
        Group {
            if viewModel.state.isLoading {
                loadingView
            } else if viewModel.state.errorLoading {
                errorView
            } else if let photo = viewModel.state.photo {
                photoDetailView(photo: photo)
            }
        }
        .task {
            await viewModel.send(.onAppear)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(.photoDetailLoadingMessage)
                .foregroundStyle(.secondary)
        }
    }

    private var errorView: some View {
        ContentUnavailableView {
            Label(.photoDetailErrorTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(.photoDetailErrorMessage)
        } actions: {
            Button(.commonRetryLabel) {
                Task { await viewModel.send(.retry) }
            }
        }
    }

    private func photoDetailView(photo: Photo) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Photo Image with Nuke for caching and zoom support
                ZoomableImageView {
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
                }
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Photo Details
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(
                        label: String(localized: .photoDetailAuthorLabel),
                        value: photo.author
                    )
                    DetailRow(
                        label: String(localized: .photoDetailDimensionsLabel),
                        value: photo.displayInfo
                    )
                    DetailRow(
                        label: String(localized: .photoDetailAspectRatioLabel),
                        value: String(format: "%.2f:1", photo.aspectRatio)
                    )
                    DetailRow(
                        label: String(localized: .photoDetailPhotoIDLabel),
                        value: photo.id
                    )
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle(.photoDetailNavigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.send(.toggleFavorite) }
                } label: {
                    Image(systemName: viewModel.state.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.state.isFavorite ? .red : .primary)
                }
            }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#if DEBUG
#Preview("Loading") {
    NavigationStack {
        PhotoDetailView(
            viewModel: PhotoDetailViewModel(
                photoId: "0",
                state: PhotoDetailViewModel.State(isLoading: true),
                useCases: PreviewContainer()
            )
        )
    }
}

#Preview("Loaded") {
    NavigationStack {
        PhotoDetailView(
            viewModel: PhotoDetailViewModel(
                photoId: "0",
                state: PhotoDetailViewModel.State(photo: .fixture()),
                useCases: PreviewContainer()
            )
        )
    }
}

#Preview("Error") {
    NavigationStack {
        PhotoDetailView(
            viewModel: PhotoDetailViewModel(
                photoId: "0",
                state: PhotoDetailViewModel.State(errorLoading: true),
                useCases: PreviewContainer()
            )
        )
    }
}

private struct PreviewContainer: HasPhotoUseCase, HasFavoriteUseCase {
    var photoUseCase: PhotoUseCase = MockPhotoUseCase()
    var favoriteUseCase: FavoriteUseCase = MockFavoriteUseCase()
}
#endif
