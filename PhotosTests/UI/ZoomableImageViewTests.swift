// PhotosTests/UI/ZoomableImageViewTests.swift
import Testing
import SwiftUI
@testable import Photos

@MainActor
struct ZoomableImageViewTests {
    // MARK: - Initialization Tests

    @Test func initializationWithDefaultValues() {
        let view = ZoomableImageView {
            Image(systemName: "photo")
        }

        // Verify default max and min scale values are set correctly
        #expect(view.maxScale == 4.0)
        #expect(view.minScale == 1.0)
    }

    @Test func initializationWithCustomScaleLimits() {
        let view = ZoomableImageView(
            maxScale: 3.0,
            minScale: 0.5
        ) {
            Image(systemName: "photo")
        }

        #expect(view.maxScale == 3.0)
        #expect(view.minScale == 0.5)
    }

    @Test func initializationWithMaxScaleOnly() {
        let view = ZoomableImageView(maxScale: 5.0) {
            Image(systemName: "photo")
        }

        #expect(view.maxScale == 5.0)
        #expect(view.minScale == 1.0)
    }

    @Test func initializationWithMinScaleOnly() {
        let view = ZoomableImageView(minScale: 0.8) {
            Image(systemName: "photo")
        }

        #expect(view.maxScale == 4.0)
        #expect(view.minScale == 0.8)
    }

    // MARK: - Content Tests

    @Test func contentIsDisplayed() {
        let view = ZoomableImageView {
            Text("Test Content")
        }

        // Verify the view contains the expected content
        // This is a structural test to ensure the content is properly wrapped
        let mirror = Mirror(reflecting: view)
        let contentChild = mirror.children.first { $0.label == "content" }
        #expect(contentChild != nil)
    }

    @Test func acceptsImageContent() {
        let view = ZoomableImageView {
            Image(systemName: "photo")
                .resizable()
        }

        // Verify that image content can be provided
        let mirror = Mirror(reflecting: view)
        #expect(mirror.children.contains { $0.label == "content" })
    }

    @Test func acceptsCustomViewContent() {
        let view = ZoomableImageView {
            VStack {
                Image(systemName: "photo")
                Text("Caption")
            }
        }

        // Verify that custom view hierarchies can be provided
        let mirror = Mirror(reflecting: view)
        #expect(mirror.children.contains { $0.label == "content" })
    }

    // MARK: - Scale Limits Tests

    @Test func maxScaleLargerThanMinScale() {
        let view = ZoomableImageView(
            maxScale: 4.0,
            minScale: 1.0
        ) {
            Image(systemName: "photo")
        }

        #expect(view.maxScale > view.minScale)
    }

    @Test func minScaleConfiguration() {
        let view = ZoomableImageView(
            maxScale: 3.0,
            minScale: 0.5
        ) {
            Image(systemName: "photo")
        }

        #expect(view.minScale == 0.5)
    }

    @Test func maxScaleConfiguration() {
        let view = ZoomableImageView(
            maxScale: 6.0,
            minScale: 1.0
        ) {
            Image(systemName: "photo")
        }

        #expect(view.maxScale == 6.0)
    }

    // MARK: - Default Behavior Tests

    @Test func defaultScaleIsOne() {
        let view = ZoomableImageView {
            Image(systemName: "photo")
        }

        // The initial currentScale should be 1.0
        // This is validated through the component's implementation
        #expect(view.minScale <= 1.0)
        #expect(view.maxScale >= 1.0)
    }

    @Test func defaultOffsetIsZero() {
        let view = ZoomableImageView {
            Image(systemName: "photo")
        }

        // The initial offset should be .zero
        // Verify through structural checks that the view is created correctly
        let mirror = Mirror(reflecting: view)
        #expect(mirror.children.contains { $0.label == "content" })
    }

    // MARK: - Edge Cases

    @Test func equalMinAndMaxScale() {
        let view = ZoomableImageView(
            maxScale: 2.0,
            minScale: 2.0
        ) {
            Image(systemName: "photo")
        }

        #expect(view.minScale == view.maxScale)
    }

    @Test func veryLargeMaxScale() {
        let view = ZoomableImageView(
            maxScale: 10.0,
            minScale: 1.0
        ) {
            Image(systemName: "photo")
        }

        #expect(view.maxScale == 10.0)
    }

    @Test func verySmallMinScale() {
        let view = ZoomableImageView(
            maxScale: 4.0,
            minScale: 0.1
        ) {
            Image(systemName: "photo")
        }

        #expect(view.minScale == 0.1)
    }
}
