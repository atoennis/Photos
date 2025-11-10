// UI/PhotoDetail/PhotoDetailView.swift
import SwiftUI

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
            Text("Loading photo details...")
                .foregroundStyle(.secondary)
        }
    }

    private var errorView: some View {
        ContentUnavailableView {
            Label("Failed to Load", systemImage: "exclamationmark.triangle")
        } description: {
            Text("Could not load photo details")
        } actions: {
            Button("Retry") {
                Task { await viewModel.send(.retry) }
            }
        }
    }

    private func photoDetailView(photo: Photo) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Photo Image
                AsyncImage(url: URL(string: photo.downloadUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(photo.aspectRatio, contentMode: .fit)
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(photo.aspectRatio, contentMode: .fit)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Photo Details
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Author", value: photo.author)
                    DetailRow(label: "Dimensions", value: photo.displayInfo)
                    DetailRow(label: "Aspect Ratio", value: String(format: "%.2f:1", photo.aspectRatio))
                    DetailRow(label: "Photo ID", value: photo.id)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Photo Details")
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
                useCases: PreviewContainer(),
                state: PhotoDetailViewModel.State(isLoading: true)
            )
        )
    }
}

#Preview("Loaded") {
    NavigationStack {
        PhotoDetailView(
            viewModel: PhotoDetailViewModel(
                photoId: "0",
                useCases: PreviewContainer(),
                state: PhotoDetailViewModel.State(photo: .fixture())
            )
        )
    }
}

#Preview("Error") {
    NavigationStack {
        PhotoDetailView(
            viewModel: PhotoDetailViewModel(
                photoId: "0",
                useCases: PreviewContainer(),
                state: PhotoDetailViewModel.State(errorLoading: true)
            )
        )
    }
}

private struct PreviewContainer: HasPhotoUseCase, HasFavoriteUseCase {
    var photoUseCase: PhotoUseCase = MockPhotoUseCase()
    var favoriteUseCase: FavoriteUseCase = MockFavoriteUseCase()
}
#endif
