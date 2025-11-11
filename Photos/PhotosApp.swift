//
//  PhotosApp.swift
//  Photos
//
//  Created by Adam Toennis on 10/30/25.
//

import SwiftUI
import SwiftData

@main
struct PhotosApp: App {
    // SwiftData model container for persistent storage
    private let modelContainer: ModelContainer

    // Dependency injection container
    private let container: DIContainer

    init() {
        // Initialize SwiftData container with schema
        do {
            let schema = Schema([
                FavoritePhotoEntity.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }

        // Initialize DI container with model container
        container = DIContainer.real(modelContainer: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                PhotoListView(
                    viewModel: .init(useCases: container, state: .init())
                )
                .tabItem {
                    Label("Photos", systemImage: "photo.fill")
                }

                FavoritesListView(
                    viewModel: .init(useCases: container, state: .init())
                )
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
            }
            .environment(\.viewModelFactory, container)
        }
        .modelContainer(modelContainer)
    }
}
