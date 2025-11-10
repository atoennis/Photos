# iOS Clean Architecture Template

This document describes the architectural patterns and structure used in this project. Use this as a blueprint for creating new iOS projects with the same architecture.

## Overview

**Architecture Pattern:** Clean Architecture with MVI (Model-View-Intent) influence

**Core Principles:**
- Clear separation of concerns across layers
- Protocol-oriented design for testability
- Dependency injection via constructor
- Unidirectional data flow
- Pure business logic isolated from frameworks

## Layer Structure

```
{AppName}/
├── {AppName}App.swift          # App entry point
├── DIContainer.swift           # Dependency injection container
├── Domain/                     # Business logic layer (pure Swift)
│   ├── Models/                 # Domain entities
│   └── UseCases/               # Business use cases
├── Data/                       # Data access layer
│   ├── Repositories/           # Repository implementations
│   ├── Models/                 # Data transfer objects (DTOs)
│   └── Networking/             # Network abstractions
├── UI/                         # Presentation layer (SwiftUI)
│   ├── {Feature}/              # Feature-specific UI modules
│   │   ├── {Feature}View.swift
│   │   └── {Feature}ViewModel.swift
│   └── Shared/                 # Shared UI components
├── Mocks/                      # Mock implementations
│   ├── Mock{Component}.swift
│   └── Responses/              # Mock JSON responses
└── Resources/                  # App resources
    ├── Assets.xcassets/
    └── Localizable.xcstrings

{AppName}Tests/                 # Test target (mirrors main structure)
├── Domain/
│   └── UseCases/
├── Data/
│   └── Repositories/
└── UI/
    └── {Feature}/
```

### Dependency Flow

```
UI Layer (Presentation)
    ↓ depends on
Domain Layer (Business Logic)
    ↓ depends on
Data Layer (Infrastructure)
```

**Key:** Lower layers never depend on higher layers. Data layer doesn't know about UI, Domain doesn't know about UI.

## Layer Responsibilities

### 1. Domain Layer

**Purpose:** Pure business logic, framework-agnostic

**Contents:**
- **Models/**: Core business entities
  - Pure Swift structs
  - Conform to `Identifiable`, `Equatable`
  - Include fixture methods in `#if DEBUG` blocks

- **UseCases/**: Business operations
  - Protocol defines interface
  - Default implementation coordinates with repositories
  - Uses `async/await` for concurrency

**Example Structure:**

```swift
// Domain/Models/Entity.swift
struct Entity: Identifiable, Equatable {
    let id: UUID
    let name: String
    // Business logic as computed properties
    var displayName: String { /* ... */ }
}

#if DEBUG
extension Entity {
    static func fixture(/* params */) -> Self { /* ... */ }
}
extension Array where Element == Entity {
    static var fixtures: [Entity] { /* ... */ }
}
#endif

// Domain/UseCases/EntityUseCase.swift
protocol HasEntityUseCase {
    var entityUseCase: EntityUseCase { get }
}

protocol EntityUseCase {
    func fetchEntities() async throws -> [Entity]
}

struct DefaultEntityUseCase: EntityUseCase {
    var repository: EntityRepository

    func fetchEntities() async throws -> [Entity] {
        try await repository.fetchEntities()
    }
}
```

### 2. Data Layer

**Purpose:** Handle data persistence, networking, and external data sources

**Contents:**
- **Repositories/**: Repository implementations
  - Implement repository protocols from domain
  - Handle data transformation (DTO → Domain)
  - Manage errors and validation

- **Models/**: Data transfer objects
  - Conform to `Codable`
  - Match API response structure
  - Include mapping methods to domain models

- **Networking/**: Network abstractions
  - Protocol wrapper for URLSession
  - Enables mock implementations

**Example Structure:**

```swift
// Data/Repositories/EntityRepository.swift
protocol EntityRepository {
    func fetchEntities() async throws -> [Entity]
}

struct DefaultEntityRepository: EntityRepository {
    let session: NetworkSession

    func fetchEntities() async throws -> [Entity] {
        // 1. Build URL and request
        guard let url = URL(string: "...") else {
            throw RepositoryError.badUrl
        }
        let request = URLRequest(url: url)

        // 2. Execute network call
        let (data, response) = try await session.data(for: request)

        // 3. Validate response
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw RepositoryError.networkError
        }

        // 4. Decode JSON to DTOs
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let json = try decoder.decode(EntitiesJSON.self, from: data)

        // 5. Map DTOs to domain models
        return json.toEntities()
    }
}

// Data/Models/EntityJSON.swift
struct EntitiesJSON: Codable {
    var entities: [EntityJSON]

    struct EntityJSON: Codable {
        let id: String
        let name: String
        // API-specific fields
    }

    func toEntities() -> [Entity] {
        entities.map { $0.toEntity() }
    }
}

extension EntitiesJSON.EntityJSON {
    func toEntity() -> Entity {
        Entity(
            id: UUID(uuidString: id) ?? UUID(),
            name: name
        )
    }
}

// Data/Networking/NetworkSession.swift
protocol NetworkSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession { }
```

### 3. UI Layer

**Purpose:** SwiftUI views and presentation logic

**Contents:**
- **{Feature}/**: Feature-specific UI modules
  - `{Feature}View.swift`: SwiftUI view
  - `{Feature}ViewModel.swift`: Presentation logic

- **Shared/**: Shared UI components and modifiers

**Example Structure:**

```swift
// UI/Feature/FeatureViewModel.swift
@Observable
@MainActor
class FeatureViewModel {
    // MVI Pattern: Actions represent user intents
    enum Action {
        case onAppear
        case refreshPulled
        case buttonTapped
        case retry
    }

    // State is equatable for testability
    struct State: Equatable {
        var entities: [Entity] = []
        var isLoading: Bool = false
        var errorLoading: Bool = false

        // Derived state as computed properties
        var isEmpty: Bool { entities.isEmpty }
    }

    // Dependencies typed by protocol composition
    typealias UseCases = HasEntityUseCase
    var useCases: UseCases
    var state: State

    init(useCases: UseCases, state: State = State()) {
        self.useCases = useCases
        self.state = state
    }

    // Unidirectional data flow
    func send(_ action: Action) async {
        switch action {
        case .onAppear, .retry:
            await fetchEntities(showLoading: true)
        case .refreshPulled:
            await fetchEntities(showLoading: false)
        case .buttonTapped:
            // Handle button action
            break
        }
    }

    private func fetchEntities(showLoading: Bool) async {
        if showLoading {
            state.isLoading = true
        }
        state.errorLoading = false

        do {
            state.entities = try await useCases.entityUseCase.fetchEntities()
            state.errorLoading = false
        } catch {
            state.errorLoading = true
        }

        state.isLoading = false
    }
}

// UI/Feature/FeatureView.swift
struct FeatureView: View {
    @State var viewModel: FeatureViewModel

    var body: some View {
        NavigationStack {
            content()
                .navigationTitle("Feature")
                .alert(
                    "Error Title",
                    isPresented: .constant(viewModel.state.errorLoading)
                ) {
                    Button("Retry") {
                        Task { await viewModel.send(.retry) }
                    }
                }
                .loading(viewModel.state.isLoading)
                .refreshable {
                    await viewModel.send(.refreshPulled)
                }
                .task {
                    await viewModel.send(.onAppear)
                }
        }
    }

    @ViewBuilder
    private func content() -> some View {
        if viewModel.state.isEmpty {
            ContentUnavailableView(
                "Empty State",
                systemImage: "tray",
                description: Text("No items available")
            )
        } else {
            List {
                ForEach(viewModel.state.entities) { entity in
                    Text(entity.name)
                }
            }
        }
    }
}

#Preview("Loaded") {
    FeatureView(
        viewModel: .init(
            useCases: DIContainer.mock(
                mockEntityUseCase: MockEntityUseCase(
                    entities: .fixtures
                )
            )
        )
    )
}

#Preview("Loading") {
    FeatureView(
        viewModel: .init(
            useCases: DIContainer.mock(
                mockEntityUseCase: MockEntityUseCase(
                    delay: 10,
                    entities: .fixtures
                )
            )
        )
    )
}

#Preview("Error") {
    FeatureView(
        viewModel: .init(
            useCases: DIContainer.mock(
                mockEntityUseCase: MockEntityUseCase(
                    throwError: true
                )
            )
        )
    )
}
```

### 4. Mocks

**Purpose:** Provide mock implementations for testing and previews

**Contents:**
- Mock implementations of protocols
- Configurable behavior (delays, errors, data)
- JSON response fixtures

**Why in main target?**
- Enables usage in SwiftUI previews
- Shared between tests and development
- Only compiled in DEBUG builds where needed

**Example Structure:**

```swift
// Mocks/MockEntityUseCase.swift
#if DEBUG
struct MockEntityUseCase: EntityUseCase {
    var delay: TimeInterval? = nil
    var entities: [Entity] = .fixtures
    var throwError: Bool = false

    func fetchEntities() async throws -> [Entity] {
        if let delay {
            try await Task.sleep(for: .seconds(delay))
        }
        guard !throwError else {
            throw MockError.mockError
        }
        return entities
    }
}

enum MockError: Error {
    case mockError
}
#endif

// Mocks/MockEntityRepository.swift
#if DEBUG
struct MockEntityRepository: EntityRepository {
    var delay: TimeInterval? = nil
    var entities: [Entity] = .fixtures
    var throwError: Bool = false

    func fetchEntities() async throws -> [Entity] {
        if let delay {
            try await Task.sleep(for: .seconds(delay))
        }
        guard !throwError else {
            throw MockError.mockError
        }
        return entities
    }
}
#endif

// Mocks/MockNetworkSession.swift
#if DEBUG
struct MockNetworkSession: NetworkSession {
    var throwError: Bool = false
    var statusCode: Int = 200
    var responseFileName: String = "fetchEntitiesSuccess"

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard !throwError,
              let resourceUrl = Bundle.main.url(
                forResource: responseFileName,
                withExtension: "json"
              ),
              let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
              ) else {
            throw URLError(.badServerResponse)
        }

        let data = try Data(contentsOf: resourceUrl)
        return (data, response)
    }
}
#endif
```

## Dependency Injection

### DIContainer Pattern

```swift
// DIContainer.swift

// 1. Compose all use case protocols
typealias AllUseCases = HasEntityUseCase // & HasOtherUseCase & ...

// 2. Container struct conforms to all protocols
struct DIContainer: AllUseCases {
    var entityUseCase: EntityUseCase
    // var otherUseCase: OtherUseCase
}

// 3. Factory methods for different configurations
extension DIContainer {
    // Production configuration
    static func real() -> DIContainer {
        // Build dependency graph from bottom up
        let networkSession = URLSession.shared
        let repository = DefaultEntityRepository(session: networkSession)
        let entityUseCase = DefaultEntityUseCase(repository: repository)

        return DIContainer(
            entityUseCase: entityUseCase
        )
    }

    // Mock configuration for tests/previews
    static func mock(
        mockEntityUseCase: EntityUseCase = MockEntityUseCase()
    ) -> DIContainer {
        DIContainer(
            entityUseCase: mockEntityUseCase
        )
    }
}
```

### App Entry Point

```swift
// {AppName}App.swift
import SwiftUI

@main
struct AppNameApp: App {
    private let container = DIContainer.real()

    var body: some Scene {
        WindowGroup {
            FeatureView(
                viewModel: .init(useCases: container)
            )
        }
    }
}
```

## Testing Structure

### Test Organization

Tests mirror the main app structure:

```
{AppName}Tests/
├── Domain/
│   └── UseCases/
│       └── EntityUseCaseTests.swift
├── Data/
│   └── Repositories/
│       └── EntityRepositoryTests.swift
└── UI/
    └── Feature/
        └── FeatureViewModelTests.swift
```

### Testing Framework

Uses **Swift Testing** (modern Xcode framework):

```swift
import Testing
@testable import AppName

@MainActor
struct FeatureViewModelTests {
    @Test
    func testOnAppear_loadsEntitiesSuccessfully() async throws {
        // Arrange
        let entities: [Entity] = .fixtures
        let subject = FeatureViewModel(
            useCases: DIContainer.mock(
                mockEntityUseCase: MockEntityUseCase(
                    entities: entities
                )
            )
        )

        // Act
        await subject.send(.onAppear)

        // Assert
        #expect(
            subject.state == FeatureViewModel.State(
                entities: entities,
                isLoading: false,
                errorLoading: false
            )
        )
    }

    @Test
    func testOnAppear_handlesError() async throws {
        // Arrange
        let subject = FeatureViewModel(
            useCases: DIContainer.mock(
                mockEntityUseCase: MockEntityUseCase(
                    throwError: true
                )
            )
        )

        // Act
        await subject.send(.onAppear)

        // Assert
        #expect(subject.state.errorLoading == true)
        #expect(subject.state.entities.isEmpty)
    }
}
```

### Testing Patterns

**Domain Layer Test:**
```swift
@MainActor
struct EntityUseCaseTests {
    @Test
    func testFetchEntities() async throws {
        // Arrange
        let entities: [Entity] = .fixtures
        let subject = DefaultEntityUseCase(
            repository: MockEntityRepository(entities: entities)
        )

        // Act
        let result = try await subject.fetchEntities()

        // Assert
        #expect(result == entities)
    }
}
```

**Data Layer Test:**
```swift
@MainActor
struct EntityRepositoryTests {
    @Test
    func testFetchEntities_success() async throws {
        // Arrange
        let subject = DefaultEntityRepository(
            session: MockNetworkSession()
        )

        // Act
        let entities = try await subject.fetchEntities()

        // Assert
        #expect(entities.count > 0)
    }

    @Test
    func testFetchEntities_networkError() async throws {
        // Arrange
        let subject = DefaultEntityRepository(
            session: MockNetworkSession(throwError: true)
        )

        // Act & Assert
        await #expect(throws: (any Error).self) {
            try await subject.fetchEntities()
        }
    }
}
```

## Naming Conventions

### Swift Files

| Type | Pattern | Example |
|------|---------|---------|
| App Entry | `{AppName}App.swift` | `MyAppApp.swift` |
| DI Container | `DIContainer.swift` | `DIContainer.swift` |
| Domain Models | `{EntityName}.swift` | `Employee.swift` |
| Use Cases | `{EntityName}UseCase.swift` | `EmployeeUseCase.swift` |
| Repositories | `{EntityName}Repository.swift` | `EmployeeRepository.swift` |
| Data Models | `{EntityName}JSON.swift` | `EmployeesJSON.swift` |
| Views | `{Feature}View.swift` | `EmployeeListView.swift` |
| ViewModels | `{Feature}ViewModel.swift` | `EmployeeListViewModel.swift` |
| View Modifiers | `{Purpose}Modifier.swift` | `LoadingModifier.swift` |
| Mocks | `Mock{ComponentName}.swift` | `MockEmployeeUseCase.swift` |
| Tests | `{ComponentName}Tests.swift` | `EmployeeUseCaseTests.swift` |

### Directories

| Type | Pattern | Example |
|------|---------|---------|
| Feature Modules | PascalCase | `Employee/` |
| Layer Names | PascalCase | `Domain/`, `Data/`, `UI/` |
| Sub-layers | PascalCase plural | `Models/`, `UseCases/`, `Repositories/` |
| Resources | PascalCase | `Resources/` |
| Mocks | `Mocks/` | `Mocks/` |
| Test Target | `{AppName}Tests/` | `MyAppTests/` |

### Localization

String keys use dot notation hierarchy:
```
{Feature}.{Context}.{type}

Examples:
- Common.Retry.label
- FeatureList.Empty.title
- FeatureList.Error.title
```

## Key Architectural Patterns

### 1. Protocol-Oriented Design

Every major component has a protocol:
- Enables testability via mocks
- Flexibility to swap implementations
- Clear contracts between layers
- Dependency inversion principle

### 2. Has* Protocol Composition

```swift
protocol HasEntityUseCase {
    var entityUseCase: EntityUseCase { get }
}

typealias AllUseCases = HasEntityUseCase & HasOtherUseCase

// ViewModels specify only needed dependencies
class ViewModel {
    typealias UseCases = HasEntityUseCase
    var useCases: UseCases
}
```

### 3. MVI (Model-View-Intent)

```swift
class ViewModel {
    enum Action { /* user intents */ }
    struct State: Equatable { /* view state */ }
    func send(_ action: Action) async { /* handle action */ }
}
```

Benefits:
- Unidirectional data flow
- Predictable state changes
- Easy to test
- Explicit user intentions

### 4. Repository Pattern

Abstracts data sources:
- Hide implementation details
- Handle data mapping (DTO → Domain)
- Manage errors
- Enables swapping sources (API, DB, cache)

**Multiple Data Sources:**
```swift
// Protocol defined in domain
protocol EmployeeRepository {
    func fetchEmployees() async throws -> [Employee]
}

// Implementations in data layer
struct EmployeeRemoteRepository: EmployeeRepository {
    let session: NetworkSession
    // Fetches from API
}

struct EmployeeLocalRepository: EmployeeRepository {
    let storage: LocalStorage
    // Fetches from local database/cache
}

// Composite pattern for cache-then-network
struct EmployeeRepository: EmployeeRepository {
    let local: EmployeeLocalRepository
    let remote: EmployeeRemoteRepository

    func fetchEmployees() async throws -> [Employee] {
        // Try local first, fallback to remote
        do {
            return try await local.fetchEmployees()
        } catch {
            let employees = try await remote.fetchEmployees()
            // Save to local cache
            return employees
        }
    }
}
```

### 5. Use Case Pattern

Encapsulates business operations:
- Single responsibility per use case
- Orchestrates between repositories
- Contains business logic
- Protocol-based for testability

## Project Configuration

### Build Settings

**Minimum Configuration:**
- Platform: iOS 17.0+ (adjust as needed)
- Language: Swift 5.0+
- UI Framework: SwiftUI
- Bundle ID: com.{company}.{AppName}

**Recommended Swift Settings:**
- Swift Concurrency: Enabled
- Approachable Concurrency: YES
- Default Actor Isolation: nonisolated
- Strict Concurrency: Complete

**Why `nonisolated` Default:**
- Data and Domain layers (repositories, use cases, models) should work from any isolation domain
- ViewModels explicitly marked with `@MainActor` where needed
- SwiftUI Views are implicitly `@MainActor` regardless of this setting
- Aligns with Clean Architecture principles: business logic shouldn't depend on UI concerns
- Results in fewer annotations as the codebase grows (most growth is in data/domain layers)

**SwiftUI Configuration:**
- Enable Previews: YES
- Generate Info.plist: YES
- Scene Manifest Generation: YES
- String Catalog Symbols: YES

### Localization Setup

1. Create `Resources/Localizable.xcstrings`
2. Enable string catalog generation in build settings
3. Use type-safe string keys:
   ```
   {Feature}.{Context}.{type}
   ```

## Adding New Features

### Step-by-Step Guide

1. **Domain Layer:**
   ```
   Domain/
   ├── Models/
   │   └── NewEntity.swift
   └── UseCases/
       └── NewEntityUseCase.swift
   ```

2. **Data Layer:**
   ```
   Data/
   ├── Repositories/
   │   └── NewEntityRepository.swift
   └── Models/
       └── NewEntityJSON.swift
   ```

3. **UI Layer:**
   ```
   UI/
   └── NewFeature/
       ├── NewFeatureView.swift
       └── NewFeatureViewModel.swift
   ```

4. **Mocks:**
   ```
   Mocks/
   ├── MockNewEntityUseCase.swift
   ├── MockNewEntityRepository.swift
   └── Responses/
       └── fetchNewEntitiesSuccess.json
   ```

5. **Tests:**
   ```
   {AppName}Tests/
   ├── Domain/UseCases/NewEntityUseCaseTests.swift
   ├── Data/Repositories/NewEntityRepositoryTests.swift
   └── UI/NewFeature/NewFeatureViewModelTests.swift
   ```

6. **Update DIContainer:**
   ```swift
   protocol HasNewEntityUseCase {
       var newEntityUseCase: NewEntityUseCase { get }
   }

   typealias AllUseCases = HasEntityUseCase & HasNewEntityUseCase

   struct DIContainer: AllUseCases {
       var entityUseCase: EntityUseCase
       var newEntityUseCase: NewEntityUseCase
   }
   ```

## Architecture Benefits

### Testability
- Every component has protocol abstraction
- Mocks included for easy testing
- State equality enables precise assertions
- Async/await testing support

### Scalability
- Clear layer separation
- Easy to add new features
- Modular by feature
- DIContainer composition

### Maintainability
- Consistent naming conventions
- Single responsibility per file
- Clear dependency flow
- Self-documenting structure

### Modern Swift
- Swift concurrency (async/await)
- Observable macro for state
- Protocol extensions
- Swift Testing framework

## Common Patterns

### Error Handling

```swift
// Domain defines error types
enum EntityError: Error {
    case notFound
    case invalidData
}

// Repository handles and transforms errors
func fetchEntities() async throws -> [Entity] {
    do {
        // ... network call
    } catch {
        throw EntityError.invalidData
    }
}

// ViewModel handles errors for UI
func send(_ action: Action) async {
    do {
        state.entities = try await useCases.entityUseCase.fetchEntities()
        state.errorLoading = false
    } catch {
        state.errorLoading = true
    }
}
```

### Loading States

```swift
struct State: Equatable {
    var isLoading: Bool = false
    var errorLoading: Bool = false
    var entities: [Entity] = []
}

// Show loading before async operation
func fetchEntities(showLoading: Bool) async {
    if showLoading {
        state.isLoading = true
    }
    // ... perform operation
    state.isLoading = false
}
```

### Pagination (If Needed)

```swift
struct State: Equatable {
    var entities: [Entity] = []
    var hasMore: Bool = true
    var currentPage: Int = 0
}

enum Action {
    case loadMore
}

func send(_ action: Action) async {
    switch action {
    case .loadMore:
        await loadNextPage()
    }
}
```

## Best Practices

1. **Keep Domain Pure**: No UIKit/SwiftUI imports in Domain layer
2. **Protocol Everything**: All major components should have protocols
3. **Test Each Layer**: Don't skip tests for any layer
4. **Use Fixtures**: Create fixtures for all domain models
5. **Mock in Main Target**: Include mocks for preview support
6. **Equatable States**: Make view model states Equatable for testing
7. **MainActor ViewModels**: Always mark ViewModels with @MainActor
8. **Async/Await**: Use modern concurrency, avoid completion handlers
9. **Preview Configurations**: Create multiple previews (loaded, loading, error, empty)
10. **Type Safety**: Use type-safe strings with xcstrings generation

---

## Quick Reference

### Adding a New Entity

1. Create domain model in `Domain/Models/`
2. Create use case protocol and implementation in `Domain/UseCases/`
3. Create repository protocol and implementation in `Data/Repositories/`
4. Create JSON DTO in `Data/Models/`
5. Create view and view model in `UI/Feature/`
6. Create mocks in `Mocks/`
7. Update `DIContainer` to include new use case
8. Add tests for each layer

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme {AppName}

# Run specific test
xcodebuild test -scheme {AppName} -only-testing:{AppName}Tests/FeatureViewModelTests
```

### Creating Previews

```swift
#Preview("State Name") {
    FeatureView(
        viewModel: .init(
            useCases: DIContainer.mock(
                mockEntityUseCase: MockEntityUseCase(
                    // Configure mock behavior
                    delay: 2,
                    throwError: false,
                    entities: .fixtures
                )
            )
        )
    )
}
```

---

This architecture provides a solid foundation for building maintainable, testable, and scalable iOS applications using modern Swift and SwiftUI.
