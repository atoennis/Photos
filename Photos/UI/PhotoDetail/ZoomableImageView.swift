// UI/PhotoDetail/ZoomableImageView.swift
import SwiftUI

/// A view that wraps any content and provides pinch-to-zoom and pan functionality
struct ZoomableImageView<Content: View>: View {
    let content: Content
    let isEnabled: Bool
    let maxScale: CGFloat
    let minScale: CGFloat
    let onScaleChange: ((CGFloat) -> Void)?

    @State private var currentScale: CGFloat = 1.0
    @State private var totalScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var totalOffset: CGSize = .zero

    init(
        isEnabled: Bool = true,
        maxScale: CGFloat = 4.0,
        minScale: CGFloat = 1.0,
        onScaleChange: ((CGFloat) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.isEnabled = isEnabled
        self.maxScale = maxScale
        self.minScale = minScale
        self.onScaleChange = onScaleChange
    }

    var body: some View {
        GeometryReader { geometry in
            let magnificationGesture = MagnificationGesture()
                .onChanged { value in
                    guard isEnabled else { return }
                    // Calculate new scale within bounds
                    // value is the scale relative to gesture start, not absolute
                    let newScale = totalScale * value
                    let clampedScale = min(max(newScale, minScale), maxScale)
                    currentScale = clampedScale
                    onScaleChange?(clampedScale)
                }
                .onEnded { _ in
                    guard isEnabled else { return }
                    totalScale = currentScale

                    // Reset offset if at or below min scale
                    if currentScale <= minScale {
                        withAnimation(.spring(response: 0.3)) {
                            currentScale = minScale
                            totalScale = minScale
                            currentOffset = .zero
                            totalOffset = .zero
                            onScaleChange?(minScale)
                        }
                    } else {
                        // Constrain offset to valid bounds for current scale
                        let constrainedOffset = constrainOffset(
                            currentOffset,
                            geometry: geometry,
                            scale: currentScale
                        )

                        if constrainedOffset != currentOffset {
                            withAnimation(.spring(response: 0.3)) {
                                currentOffset = constrainedOffset
                                totalOffset = constrainedOffset
                            }
                        } else {
                            totalOffset = currentOffset
                        }
                    }
                }

            let dragGesture = DragGesture()
                .onChanged { value in
                    guard isEnabled else { return }
                    // Only allow panning if zoomed in
                    guard currentScale > 1.0 else { return }

                    let newOffset = CGSize(
                        width: totalOffset.width + value.translation.width,
                        height: totalOffset.height + value.translation.height
                    )

                    // Constrain offset to prevent excessive panning
                    currentOffset = constrainOffset(
                        newOffset,
                        geometry: geometry,
                        scale: currentScale
                    )
                }
                .onEnded { _ in
                    guard isEnabled else { return }
                    totalOffset = currentOffset
                }

            let doubleTapGesture = TapGesture(count: 2)
                .onEnded {
                    guard isEnabled else { return }
                    withAnimation(.spring(response: 0.3)) {
                        if currentScale > 1.0 {
                            // Zoom out to original size
                            currentScale = 1.0
                            totalScale = 1.0
                            currentOffset = .zero
                            totalOffset = .zero
                            onScaleChange?(1.0)
                        } else {
                            // Zoom in to 2x
                            currentScale = 2.0
                            totalScale = 2.0
                            onScaleChange?(2.0)
                        }
                    }
                }

            content
                .scaleEffect(currentScale)
                .offset(x: currentOffset.width, y: currentOffset.height)
                .highPriorityGesture(magnificationGesture)
                .highPriorityGesture(dragGesture)
                .simultaneousGesture(doubleTapGesture)
        }
    }

    /// Constrains the offset to keep content within valid bounds for the given scale
    private func constrainOffset(
        _ offset: CGSize,
        geometry: GeometryProxy,
        scale: CGFloat
    ) -> CGSize {
        // Calculate maximum allowed offset based on scale
        // When zoomed, content can be offset by half the "extra" size created by scaling
        let maxOffsetX = (geometry.size.width * (scale - 1)) / 2
        let maxOffsetY = (geometry.size.height * (scale - 1)) / 2

        return CGSize(
            width: min(max(offset.width, -maxOffsetX), maxOffsetX),
            height: min(max(offset.height, -maxOffsetY), maxOffsetY)
        )
    }
}

#if DEBUG
#Preview("Zoomable Image") {
    ZoomableImageView {
        Image(systemName: "photo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.2))
    }
}
#endif
