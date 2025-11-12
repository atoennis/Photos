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
        PhotoDetailContent(
            isFavorite: viewModel.state.isFavorite,
            onToggleFavorite: {
                Task { await viewModel.send(.toggleFavorite) }
            },
            photo: photo
        )
    }
}

/// The main content view for photo detail with swipe-up panel interaction
private struct PhotoDetailContent: View {
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let photo: Photo

    @State private var isDetailPanelExpanded: Bool = false
    @State private var dragOffset: CGFloat = 0

    private let panelHeight: CGFloat = 220
    private let dragThreshold: CGFloat = 50

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Full-screen photo with zoom
                photoLayer
                    .ignoresSafeArea()

                // Layer 2: Detail panel overlay
                detailPanelLayer(geometry: geometry)
            }
        }
        .navigationTitle(.photoDetailNavigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(isDetailPanelExpanded ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onToggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : .primary)
                }
            }
        }
    }

    private var photoLayer: some View {
        ZoomableImageView(isEnabled: !isDetailPanelExpanded) {
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
                                .font(.largeTitle)
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
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only respond to swipe up when panel is not expanded
                    guard !isDetailPanelExpanded else { return }

                    let translation = value.translation.height

                    // Only track upward drags
                    if translation < 0 {
                        dragOffset = translation
                    }
                }
                .onEnded { value in
                    let translation = value.translation.height

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        // Check if dragged up far enough to expand
                        if !isDetailPanelExpanded && translation < -dragThreshold {
                            isDetailPanelExpanded = true
                        }

                        dragOffset = 0
                    }
                }
        )
    }

    private func detailPanelLayer(geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            PhotoDetailPanel(photo: photo)
                .offset(y: panelOffset(geometry: geometry))
                .gesture(panelDragGesture(geometry: geometry))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isDetailPanelExpanded)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
        }
    }

    private func panelOffset(geometry: GeometryProxy) -> CGFloat {
        let hiddenOffset = panelHeight + geometry.safeAreaInsets.bottom

        if isDetailPanelExpanded {
            // Panel is expanded - show it with any active drag offset
            return dragOffset
        } else {
            // Panel is collapsed - hide it below screen, adjusted by drag
            return hiddenOffset + dragOffset
        }
    }

    private func panelDragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.height

                if isDetailPanelExpanded {
                    // Dragging down to collapse - only allow downward movement
                    dragOffset = max(0, translation)
                }
                // Note: Upward drags when collapsed are handled by photoLayer gesture
            }
            .onEnded { value in
                let translation = value.translation.height

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if isDetailPanelExpanded && translation > dragThreshold {
                        // Dragged down far enough to collapse
                        isDetailPanelExpanded = false
                    }

                    dragOffset = 0
                }
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
