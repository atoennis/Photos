// PhotoModelTests.swift
import Testing
@testable import Photos

struct PhotoModelTests {

    @Test func photoDisplayInfo() {
        let photo = Photo.fixture(height: 1080, width: 1920)

        #expect(photo.displayInfo == "1920 × 1080")
    }

    @Test func photoAspectRatio() {
        let photo = Photo.fixture(height: 1080, width: 1920)

        #expect(photo.aspectRatio == 1920.0 / 1080.0)
    }

    @Test func photoAspectRatioSquare() {
        let photo = Photo.fixture(height: 1000, width: 1000)

        #expect(photo.aspectRatio == 1.0)
    }

    @Test func photoAspectRatioPortrait() {
        let photo = Photo.fixture(height: 1920, width: 1080)

        #expect(photo.aspectRatio == 1080.0 / 1920.0)
    }

    @Test func photoEquality() {
        let photo1 = Photo.fixture(author: "John", id: "1")
        let photo2 = Photo.fixture(author: "John", id: "1")
        let photo3 = Photo.fixture(author: "Jane", id: "2")

        #expect(photo1 == photo2)
        #expect(photo1 != photo3)
    }
}
