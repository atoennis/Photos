//
//  PhotosApp.swift
//  Photos
//
//  Created by Adam Toennis on 10/30/25.
//

import SwiftUI

@main
struct PhotosApp: App {
    private let container = DIContainer.real()

    var body: some Scene {
        WindowGroup {
            PhotoListView(
                viewModel: .init(useCases: container, state: .init())
            )
        }
    }
}
