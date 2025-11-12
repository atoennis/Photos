// UI/PhotoDetail/PhotoDetailPanel.swift
import SwiftUI

/// A panel that displays photo metadata with a drag handle
/// Designed to slide up from the bottom of the screen
struct PhotoDetailPanel: View {
    let photo: Photo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Drag handle (visual affordance)
            dragHandle
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Metadata content
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
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 10,
            x: 0,
            y: -5
        )
    }

    private var dragHandle: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.5))
            .frame(width: 36, height: 5)
            .frame(maxWidth: .infinity)
    }
}

/// A row displaying a label-value pair
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
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

#if DEBUG
#Preview("Photo Detail Panel") {
    VStack {
        Spacer()
        PhotoDetailPanel(photo: .fixture())
            .padding()
    }
    .background(Color.gray.opacity(0.3))
}

#Preview("Photo Detail Panel - Long Values") {
    VStack {
        Spacer()
        PhotoDetailPanel(
            photo: Photo(
                aspectRatio: 1.5,
                author: "A Very Long Author Name That Should Truncate",
                downloadUrl: "https://example.com/photo.jpg",
                height: 4000,
                id: "12345678901234567890",
                url: "https://example.com",
                width: 6000
            )
        )
        .padding()
    }
    .background(Color.gray.opacity(0.3))
}
#endif
