// PhotoJSONTests.swift
import Testing
import Foundation
@testable import Photos

struct PhotoJSONTests {

    @Test func photoJSONDecoding() throws {
        let json = """
        {
            "id": "0",
            "author": "Alejandro Escamilla",
            "width": 5616,
            "height": 3744,
            "url": "https://unsplash.com/photos/yC-Yzbqy7PY",
            "download_url": "https://picsum.photos/id/0/5616/3744"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let photoJSON = try decoder.decode(PhotoJSON.self, from: data)

        #expect(photoJSON.id == "0")
        #expect(photoJSON.author == "Alejandro Escamilla")
        #expect(photoJSON.width == 5616)
        #expect(photoJSON.height == 3744)
        #expect(photoJSON.url == "https://unsplash.com/photos/yC-Yzbqy7PY")
        #expect(photoJSON.downloadUrl == "https://picsum.photos/id/0/5616/3744")
    }

    @Test func photoJSONArrayDecoding() throws {
        let json = """
        [
            {
                "id": "0",
                "author": "Alejandro Escamilla",
                "width": 5616,
                "height": 3744,
                "url": "https://unsplash.com/photos/yC-Yzbqy7PY",
                "download_url": "https://picsum.photos/id/0/5616/3744"
            },
            {
                "id": "1",
                "author": "Alejandro Escamilla",
                "width": 5616,
                "height": 3744,
                "url": "https://unsplash.com/photos/LNRyGwIJr5c",
                "download_url": "https://picsum.photos/id/1/5616/3744"
            }
        ]
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let photoJSONArray = try decoder.decode([PhotoJSON].self, from: data)

        #expect(photoJSONArray.count == 2)
        #expect(photoJSONArray[0].id == "0")
        #expect(photoJSONArray[1].id == "1")
    }

    @Test func photoJSONToPhoto() {
        let photoJSON = PhotoJSON(
            author: "Alejandro Escamilla",
            downloadUrl: "https://picsum.photos/id/0/5616/3744",
            height: 3744,
            id: "0",
            url: "https://unsplash.com/photos/yC-Yzbqy7PY",
            width: 5616
        )

        let photo = photoJSON.toPhoto()

        #expect(photo.id == photoJSON.id)
        #expect(photo.author == photoJSON.author)
        #expect(photo.width == photoJSON.width)
        #expect(photo.height == photoJSON.height)
        #expect(photo.url == photoJSON.url)
        #expect(photo.downloadUrl == photoJSON.downloadUrl)
    }

    @Test func photoJSONArrayToPhotos() {
        let photoJSONArray = [
            PhotoJSON(
                author: "Alejandro Escamilla",
                downloadUrl: "https://picsum.photos/id/0/5616/3744",
                height: 3744,
                id: "0",
                url: "https://unsplash.com/photos/yC-Yzbqy7PY",
                width: 5616
            ),
            PhotoJSON(
                author: "Alejandro Escamilla",
                downloadUrl: "https://picsum.photos/id/1/5616/3744",
                height: 3744,
                id: "1",
                url: "https://unsplash.com/photos/LNRyGwIJr5c",
                width: 5616
            )
        ]

        let photos = photoJSONArray.toPhotos()

        #expect(photos.count == 2)
        #expect(photos[0].id == "0")
        #expect(photos[1].id == "1")
    }
}
