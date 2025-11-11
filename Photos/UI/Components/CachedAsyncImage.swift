// UI/Components/CachedAsyncImage.swift
import SwiftUI
import NukeUI

/// A cached async image view powered by Nuke
///
/// This view provides similar functionality to SwiftUI's AsyncImage but with
/// aggressive disk and memory caching via Nuke. Images are cached using HTTP
/// caching headers and stored offline for improved scrolling performance.
struct CachedAsyncImage<Content: View, Placeholder: View, FailureView: View>: View {
    let url: URL?
    let aspectRatio: CGFloat?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let failure: () -> FailureView

    var body: some View {
        if let url {
            LazyImage(url: url) { state in
                if let image = state.image {
                    content(image)
                } else if state.error != nil {
                    failure()
                } else {
                    placeholder()
                }
            }
        } else {
            failure()
        }
    }
}

// MARK: - Convenience Initializers

extension CachedAsyncImage where Content == AnyView, Placeholder == AnyView, FailureView == AnyView {
    /// Creates a cached async image with phase-based content builder
    init(
        url: URL?,
        aspectRatio: CGFloat? = nil,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> some View
    ) {
        self.url = url
        self.aspectRatio = aspectRatio

        // Convert Nuke's state to SwiftUI's AsyncImagePhase for compatibility
        self.content = { image in
            AnyView(content(.success(image)))
        }
        self.placeholder = {
            AnyView(content(.empty))
        }
        self.failure = {
            AnyView(content(.failure(NSError(domain: "ImageLoading", code: -1))))
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Success case
        CachedAsyncImage(
            url: URL(string: "https://picsum.photos/id/237/400/300"),
            aspectRatio: 4/3
        ) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(4/3, contentMode: .fit)
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
                    .aspectRatio(4/3, contentMode: .fit)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            @unknown default:
                EmptyView()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding()

        // Failure case
        CachedAsyncImage(
            url: URL(string: "invalid"),
            aspectRatio: 16/9
        ) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image.resizable()
            case .failure:
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.red)
            @unknown default:
                EmptyView()
            }
        }
        .frame(height: 200)
    }
}
