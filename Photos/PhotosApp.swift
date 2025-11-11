//
//  PhotosApp.swift
//  Photos
//
//  Created by Adam Toennis on 10/30/25.
//

import SwiftUI
import Nuke

@main
struct PhotosApp: App {
    // Dependency injection container
    private let container: DIContainer

    init() {
        // Configure Nuke image pipeline with aggressive caching
        configureImagePipeline()

        // Initialize DI container with model container
        container = DIContainer.real()
    }

    /// Configures Nuke's image pipeline with HTTP-based caching
    private func configureImagePipeline() {
        let pipeline = ImagePipeline {
            // Use HTTP cache policy - respect cache-control headers
            $0.dataLoader = DataLoader(configuration: {
                let config = DataLoader.defaultConfiguration
                config.urlCache = URLCache(
                    memoryCapacity: 100 * 1024 * 1024,  // 100 MB memory cache
                    diskCapacity: 200 * 1024 * 1024     // 200 MB disk cache
                )
                // Respect HTTP caching headers
                config.requestCachePolicy = .returnCacheDataElseLoad
                return config
            }())

            // Configure image cache (decoded images)
            $0.imageCache = ImageCache(
                costLimit: 100 * 1024 * 1024,  // 100 MB memory limit
                countLimit: 100                 // Max 100 images in memory
            )

            // Enable aggressive disk caching
            $0.dataCache = try? DataCache(name: "com.adamtoennis.Photos.cache")

            // Disable rate limiter for faster loading
            $0.isRateLimiterEnabled = false
        }

        ImagePipeline.shared = pipeline
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
