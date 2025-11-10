// Domain/Models/Photo.swift
import Foundation

struct Photo: Identifiable, Equatable {
    let author: String
    let downloadUrl: String
    let height: Int
    let id: String
    let url: String
    let width: Int

    var aspectRatio: Double {
        Double(width) / Double(height)
    }

    var displayInfo: String {
        "\(width) × \(height)"
    }
}

#if DEBUG
extension Photo {
    static func fixture(
        author: String = "Alejandro Escamilla",
        downloadUrl: String = "https://picsum.photos/id/0/5616/3744",
        height: Int = 3744,
        id: String = "0",
        url: String = "https://unsplash.com/photos/yC-Yzbqy7PY",
        width: Int = 5616
    ) -> Self {
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

extension Array where Element == Photo {
    static var fixtures: [Photo] {
        [
            .fixture(
                author: "Alejandro Escamilla",
                height: 3744,
                id: "0",
                width: 5616
            ),
            .fixture(
                author: "Alejandro Escamilla",
                height: 3744,
                id: "1",
                width: 5616
            ),
            .fixture(
                author: "Paul Jarvis",
                height: 1667,
                id: "10",
                width: 2500
            ),
            .fixture(
                author: "Tina Rataj",
                height: 1656,
                id: "100",
                width: 2500
            ),
            .fixture(
                author: "Lukas Budimaier",
                height: 3635,
                id: "1000",
                width: 5626
            )
        ]
    }
}
#endif
