// UI/Environment/ViewModelFactoryKey.swift
import SwiftUI

/// Environment key for injecting ViewModelFactory throughout the app
private struct ViewModelFactoryKey: EnvironmentKey {
    static let defaultValue: ViewModelFactory = DIContainer.mock()
}

extension EnvironmentValues {
    var viewModelFactory: ViewModelFactory {
        get { self[ViewModelFactoryKey.self] }
        set { self[ViewModelFactoryKey.self] = newValue }
    }
}
