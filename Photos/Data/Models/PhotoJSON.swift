// Data/Models/PhotoJSON.swift
import Foundation

struct PhotoJSON: Codable {
    let author: String
    let downloadUrl: String
    let height: Int
    let id: String
    let url: String
    let width: Int

    func toPhoto() -> Photo {
        Photo(
            author: author,
            downloadUrl: downloadUrl,
            height: height,
            id: id,
            url: url,
            width: width
        )
    }
}

extension Array where Element == PhotoJSON {
    func toPhotos() -> [Photo] {
        map { $0.toPhoto() }
    }
}

#if DEBUG
extension PhotoJSON {
    static func fixture(
        author: String = "Alejandro Escamilla",
        downloadUrl: String = "https://picsum.photos/id/0/5616/3744",
        height: Int = 3744,
        id: String = "0",
        url: String = "https://unsplash.com/photos/yC-Yzbqy7PY",
        width: Int = 5616
    ) -> Self {
        PhotoJSON(
            author: author,
            downloadUrl: downloadUrl,
            height: height,
            id: id,
            url: url,
            width: width
        )
    }
}

extension Array where Element == PhotoJSON {
    static var fixtures: [PhotoJSON] {
        [
            .fixture(
                author: "Alejandro Escamilla",
                downloadUrl: "https://picsum.photos/id/0/5616/3744",
                height: 3744,
                id: "0",
                url: "https://unsplash.com/photos/yC-Yzbqy7PY",
                width: 5616
            ),
            .fixture(
                author: "Alejandro Escamilla",
                downloadUrl: "https://picsum.photos/id/1/5616/3744",
                height: 3744,
                id: "1",
                url: "https://unsplash.com/photos/LNRyGwIJr5c",
                width: 5616
            ),
            .fixture(
                author: "Paul Jarvis",
                downloadUrl: "https://picsum.photos/id/10/2500/1667",
                height: 1667,
                id: "10",
                url: "https://unsplash.com/photos/6J--NXulQCs",
                width: 2500
            ),
            .fixture(
                author: "Tina Rataj",
                downloadUrl: "https://picsum.photos/id/100/2500/1656",
                height: 1656,
                id: "100",
                url: "https://unsplash.com/photos/pwaaqfoMibI",
                width: 2500
            ),
            .fixture(
                author: "Lukas Budimaier",
                downloadUrl: "https://picsum.photos/id/1000/5626/3635",
                height: 3635,
                id: "1000",
                url: "https://unsplash.com/photos/6cY-FvMlmkQ",
                width: 5626
            )
        ]
    }
}
#endif
