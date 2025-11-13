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
    @State private var navigationOpacity: CGFloat = 1.0

    private let panelHeight: CGFloat = 220
    private let dragThreshold: CGFloat = 50

    /// Calculate drag progress (0.0 = collapsed, 1.0 = expanded)
    private var dragProgress: CGFloat {
        if isDetailPanelExpanded {
            // Expanded state - calculate based on drag down
            let downwardDrag = max(0, dragOffset)
            return max(0, 1.0 - (downwardDrag / panelHeight))
        } else {
            // Collapsed state - calculate based on drag up
            let upwardDrag = min(0, dragOffset)
            return min(1.0, abs(upwardDrag) / panelHeight)
        }
    }

    /// Check if user has started dragging from initial state
    private var hasDraggedFromInitial: Bool {
        dragProgress > 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Full-screen photo with zoom
                photoLayer(geometry: geometry)
                    .ignoresSafeArea()

                // Layer 2: Detail panel overlay
                detailPanelLayer(geometry: geometry)
            }
        }
        .navigationTitle(navigationOpacity > 0 ? .photoDetailNavigationTitle : "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(navigationOpacity < 1.0)
        .toolbar {
            if navigationOpacity > 0 {
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
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(
            Color.black.opacity(navigationOpacity * 0.5),
            for: .navigationBar
        )
        .onChange(of: hasDraggedFromInitial) { _, hasDragged in
            withAnimation(.easeInOut(duration: 0.25)) {
                navigationOpacity = hasDragged ? 0.0 : 1.0
            }
        }
    }

    private func photoLayer(geometry: GeometryProxy) -> some View {
        // Interpolate scale: 1.0 when collapsed, 2.0 when expanded (zoomed in)
        let imageScale = 1.0 + (dragProgress * 1.0)

        // Calculate position offset
        let yOffset: CGFloat = {
            let targetOffset = -(geometry.size.height / 4)
            return targetOffset * dragProgress + (dragOffset / 2)
        }()

        return ZStack {
            Color.clear
                .contentShape(Rectangle())

            ZoomableImageView(isEnabled: !isDetailPanelExpanded) {
                LazyImage(url: URL(string: photo.downloadUrl)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if state.error != nil {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(photo.aspectRatio, contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                                    .font(.largeTitle)
                            }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(photo.aspectRatio, contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay {
                                ProgressView()
                            }
                    }
                }
            }
            .scaleEffect(imageScale)
            .offset(y: yOffset)
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.86), value: imageScale)
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.86), value: yOffset)
            .allowsHitTesting(!isDetailPanelExpanded)
        }
        .highPriorityGesture(
            DragGesture()
                .onChanged { value in
                    let translation = value.translation.height

                    if isDetailPanelExpanded {
                        // Expanded: allow drag down to collapse
                        if translation > 0 {
                            dragOffset = translation
                        }
                    } else {
                        // Collapsed: allow drag up to expand
                        if translation < 0 {
                            dragOffset = translation
                        }
                    }
                }
                .onEnded { value in
                    let translation = value.translation.height

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if isDetailPanelExpanded {
                            // Check if dragged down far enough to collapse
                            if translation > dragThreshold {
                                isDetailPanelExpanded = false
                            }
                        } else {
                            // Check if dragged up far enough to expand
                            if translation < -dragThreshold {
                                isDetailPanelExpanded = true
                            }
                        }

                        dragOffset = 0
                    }
                }
        )
    }

    private func detailPanelLayer(geometry: GeometryProxy) -> some View {
        // Calculate image's yOffset (same as in photoLayer)
        let imageYOffset: CGFloat = {
            let targetOffset = -(geometry.size.height / 4)
            return targetOffset * dragProgress + (dragOffset / 2)
        }()

        // Calculate image scale (same as in photoLayer)
        let imageScale = 1.0 + (dragProgress * 1.0)

        // Estimate image height (assuming typical aspect ratio, image fits within screen width)
        // Conservative estimate: image takes up about 1/3 of screen height when unscaled
        let estimatedImageHeight = geometry.size.height / 3

        // Panel sits at: image center + yOffset + (half of scaled image height) + spacing
        let panelYPosition = (geometry.size.height / 2) + imageYOffset + (estimatedImageHeight * imageScale / 2) + 16

        return VStack(spacing: 0) {
            PhotoDetailPanel(photo: photo)
                .opacity(dragProgress)
                .gesture(panelDragGesture(geometry: geometry))
                .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.86), value: dragProgress)
        }
        .frame(maxWidth: .infinity)
        .position(x: geometry.size.width / 2, y: panelYPosition)
        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.86), value: panelYPosition)
    }

    private func panelDragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.height

                if isDetailPanelExpanded {
                    // Dragging down to collapse - track the drag
                    if translation > 0 {
                        dragOffset = translation
                    }
                }
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
