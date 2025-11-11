//
//  PhotosApp.swift
//  Photos
//
//  Created by Adam Toennis on 10/30/25.
//

import SwiftUI

@main
struct PhotosApp: App {
    // Dependency injection container
    private let container: DIContainer

    init() {
        // Initialize DI container with model container
        container = DIContainer.real()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                PhotoListView(
                    viewModel: .init(state: .init(), useCases: container)
                )
                .tabItem {
                    Label("Photos", systemImage: "photo.fill")
                }

                FavoritesListView(
                    viewModel: .init(state: .init(), useCases: container)
                )
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
            }
            .environment(\.viewModelFactory, container)
        }
    }
}
