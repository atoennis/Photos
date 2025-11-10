# Photos - iOS Clean Architecture Project

This project uses Clean Architecture with MVI (Model-View-Intent) influence for building maintainable, testable, and scalable iOS applications.

## Architecture Overview

The project follows a layered architecture with clear separation of concerns:

```
Photos/
├── PhotosApp.swift        # App entry point
├── DIContainer.swift      # Dependency injection container
├── Domain/                # Business logic layer (pure Swift)
│   ├── Models/           # Domain entities
│   └── UseCases/         # Business use cases
├── Data/                 # Data access layer
│   ├── Repositories/     # Repository implementations
│   ├── Models/           # Data transfer objects (DTOs)
│   └── Networking/       # Network abstractions
├── UI/                   # Presentation layer (SwiftUI)
│   └── Shared/           # Shared UI components
├── Mocks/                # Mock implementations
│   └── Responses/        # Mock JSON responses
└── Resources/            # App resources
    ├── Assets.xcassets/
    └── Localizable.xcstrings
```

## Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Project Setup

1. Open `Photos.xcodeproj` in Xcode
2. Build and run the project (⌘R)

### Recommended Build Settings

Configure these settings in Xcode:

**Swift Concurrency:**
- Swift Concurrency: Enabled
- Approachable Concurrency: YES
- Default Actor Isolation: MainActor
- Strict Concurrency: Complete

**SwiftUI Configuration:**
- Enable Previews: YES
- Generate Info.plist: YES
- Scene Manifest Generation: YES
- String Catalog Symbols: YES

## Architecture Details

For detailed information about the architecture patterns, layer responsibilities, and best practices, see [ARCHITECTURE.md](Photos/ARCHITECTURE.md).

## Current Implementation

The app fetches and displays photos from the [Lorem Picsum API](https://picsum.photos):

- **Endpoint**: `https://picsum.photos/v2/list`
- **Features**: Photo list with images, author names, and dimensions
- **UI**: SwiftUI with AsyncImage for photo loading
- **Architecture**: Full Clean Architecture with Domain, Data, and UI layers

## Adding Your First Feature

Follow these steps to add a new feature:

### 1. Create Domain Model

```swift
// Domain/Models/MyEntity.swift
struct MyEntity: Identifiable, Equatable {
    let id: UUID
    let name: String
    let description: String
}

#if DEBUG
extension MyEntity {
    static func fixture(
        id: UUID = UUID(),
        name: String = "Example",
        description: String = "An example entity"
    ) -> Self {
        MyEntity(id: id, name: name, description: description)
    }
}

extension Array where Element == MyEntity {
    static var fixtures: [MyEntity] {
        [
            .fixture(name: "First"),
            .fixture(name: "Second"),
            .fixture(name: "Third")
        ]
    }
}
#endif
```

### 2. Create Use Case

```swift
// Domain/UseCases/MyEntityUseCase.swift
protocol HasMyEntityUseCase {
    var myEntityUseCase: MyEntityUseCase { get }
}

protocol MyEntityUseCase {
    func fetchEntities() async throws -> [MyEntity]
}

struct DefaultMyEntityUseCase: MyEntityUseCase {
    var repository: MyEntityRepository

    func fetchEntities() async throws -> [MyEntity] {
        try await repository.fetchEntities()
    }
}
```

### 3. Create Repository

```swift
// Data/Repositories/MyEntityRepository.swift
protocol MyEntityRepository {
    func fetchEntities() async throws -> [MyEntity]
}

struct DefaultMyEntityRepository: MyEntityRepository {
    let session: NetworkSession

    func fetchEntities() async throws -> [MyEntity] {
        // Implementation here
        // See ARCHITECTURE.md for detailed example
    }
}
```

### 4. Create Mock Implementations

```swift
// Mocks/MockMyEntityUseCase.swift
#if DEBUG
struct MockMyEntityUseCase: MyEntityUseCase {
    var delay: TimeInterval? = nil
    var entities: [MyEntity] = .fixtures
    var throwError: Bool = false

    func fetchEntities() async throws -> [MyEntity] {
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
```

### 5. Update DIContainer

```swift
// DIContainer.swift
typealias AllUseCases = HasPhotoUseCase & HasMyEntityUseCase

struct DIContainer: AllUseCases {
    var photoUseCase: PhotoUseCase
    var myEntityUseCase: MyEntityUseCase
}

extension DIContainer {
    static func real() -> DIContainer {
        let networkSession = URLSession.shared
        let photoRepository = DefaultPhotoRepository(session: networkSession)
        let photoUseCase = DefaultPhotoUseCase(repository: photoRepository)
        let myEntityRepository = DefaultMyEntityRepository(session: networkSession)
        let myEntityUseCase = DefaultMyEntityUseCase(repository: myEntityRepository)

        return DIContainer(
            photoUseCase: photoUseCase,
            myEntityUseCase: myEntityUseCase
        )
    }

    static func mock(
        mockPhotoUseCase: PhotoUseCase? = nil,
        mockMyEntityUseCase: MyEntityUseCase? = nil
    ) -> DIContainer {
        DIContainer(
            photoUseCase: mockPhotoUseCase ?? MockPhotoUseCase(),
            myEntityUseCase: mockMyEntityUseCase ?? MockMyEntityUseCase()
        )
    }
}
```

### 6. Create View and ViewModel

See ARCHITECTURE.md for complete examples of:
- ViewModel with Action/State pattern
- SwiftUI View implementation
- Multiple preview configurations

## Testing

Run tests with:

```bash
# Run all tests
xcodebuild test -scheme Photos

# Run specific test
xcodebuild test -scheme Photos -only-testing:PhotosTests/FeatureViewModelTests
```

## Key Principles

1. **Protocol-Oriented Design**: All major components use protocols for testability
2. **Dependency Injection**: Dependencies passed via constructor, configured in DIContainer
3. **Unidirectional Data Flow**: MVI pattern with Actions → State changes
4. **Layer Separation**: UI → Domain → Data (dependencies only flow downward)
5. **Mock in Main Target**: Mocks wrapped in `#if DEBUG` for preview support

## Resources

- [ARCHITECTURE.md](Photos/ARCHITECTURE.md) - Complete architectural documentation
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Swift.org](https://swift.org/)

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]
