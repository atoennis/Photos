// UI/PhotoList/PhotoListView.swift
import SwiftUI

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

struct PhotoRowView: View {
    let photo: Photo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Display the photo using AsyncImage
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
            .clipShape(RoundedRectangle(cornerRadius: 8))

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
            useCases: DIContainer.mock(
                photoUseCase: MockPhotoUseCase(
                    photos: .fixtures
                )
            ),
            state: .init()
        )
    )
}

#Preview("Loading") {
    PhotoListView(
        viewModel: .init(
            useCases: DIContainer.mock(
                photoUseCase: MockPhotoUseCase(
                    delay: 10,
                    photos: .fixtures
                )
            ),
            state: .init()
        )
    )
}

#Preview("Error") {
    PhotoListView(
        viewModel: .init(
            useCases: DIContainer.mock(
                photoUseCase: MockPhotoUseCase(
                    throwError: true
                )
            ),
            state: .init()
        )
    )
}

#Preview("Empty") {
    PhotoListView(
        viewModel: .init(
            useCases: DIContainer.mock(
                photoUseCase: MockPhotoUseCase(
                    photos: []
                )
            ),
            state: .init()
        )
    )
}
