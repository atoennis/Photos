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
            Text("PhotoDetail.Loading.message", bundle: .main)
                .foregroundStyle(.secondary)
        }
    }

    private var errorView: some View {
        ContentUnavailableView {
            Label("PhotoDetail.Error.title", systemImage: "exclamationmark.triangle")
        } description: {
            Text("PhotoDetail.Error.message", bundle: .main)
        } actions: {
            Button("Common.Retry.label") {
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
                        systemImage: "person.fill",
                        value: photo.author
                    )
                    DetailRow(
                        systemImage: "arrow.up.left.and.arrow.down.right",
                        value: photo.displayInfo
                    )
                    DetailRow(
                        systemImage: "aspectratio.fill",
                        value: String(format: "%.2f:1", photo.aspectRatio)
                    )
                    DetailRow(
                        systemImage: "number",
                        value: photo.id
                    )
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("PhotoDetail.NavigationTitle")
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
    let systemImage: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 20)
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
