# Photos iOS App - Project Context

## Overview
A modern iOS photo browsing application built with SwiftUI, demonstrating Clean Architecture principles with strict Swift 6 concurrency compliance.

## Architecture
This project follows **Clean Architecture** with **MVVM** pattern and unidirectional data flow (MVI-inspired).

**Full architecture documentation:** [ARCHITECTURE.md](./ARCHITECTURE.md)

### Layer Structure
```
UI Layer (Presentation)
    ↓ depends on
Domain Layer (Business Logic)
    ↓ depends on
Data Layer (Infrastructure)
```

- **UI Layer:** SwiftUI Views + ViewModels (marked `@MainActor`)
- **Domain Layer:** Models, Use Cases, Repository protocols (nonisolated)
- **Data Layer:** Repository implementations, DTOs, Networking (nonisolated)

## Swift 6 Concurrency Strategy

### Actor Isolation
- **Default Actor Isolation:** `nonisolated`
- **Strict Concurrency:** Complete (enabled)
- **ViewModels:** Explicitly marked with `@MainActor`
- **SwiftUI Views:** Implicitly `@MainActor` (no annotation needed)
- **Data/Domain types:** Remain nonisolated for flexibility

### Why nonisolated Default?
- Data and Domain layers (60% of codebase) should work from any isolation domain
- ViewModels explicitly declare their MainActor requirement
- Aligns with Clean Architecture: business logic shouldn't depend on UI concerns
- More scalable as data/domain layers grow

### Concurrency Guidelines
- All async operations use structured concurrency (avoid unstructured `Task {}`)
- Protocol types crossing actor boundaries should be `Sendable`
- Value types (structs) with immutable properties are automatically `Sendable`
- Use `.task { }` modifier in SwiftUI for proper lifecycle management

## Key Conventions

### Code Style

#### Function and Initializer Parameters
- **Multi-line formatting:** Always use multi-line formatting when there are 2 or more parameters
- **Alphabetical ordering:** All parameters must be in alphabetical order
  - **Exception:** Trailing closures should remain at the end and are exempt from alphabetical ordering
- **Format example:**
  ```swift
  func fetchPhotos(
      limit: Int,
      sortOrder: SortOrder
  ) async throws -> [Photo]

  init(
      repository: PhotoRepository,
      useCase: PhotoUseCase
  ) {
      self.repository = repository
      self.useCase = useCase
  }

  // Trailing closure exception
  func performTask(
      delay: TimeInterval,
      priority: TaskPriority,
      operation: () async -> Void
  ) async {
      // operation closure remains at end despite alphabetically being first
  }
  ```

#### Testing Requirements
- **Always include tests** for new functionality and changes
- **Test coverage:** Minimum one success case + one failure/error case per public function
- **Test location:** Tests must be in corresponding test file (e.g., `PhotoListViewModel` → `PhotoListViewModelTests`)
- **Project inclusion:** When creating new test files, ensure they are added to the Xcode project file (`Photos.xcodeproj`) so they are discovered and run by the test runner

#### String Localization
- **Never use hard-coded strings** in user-facing code
- **Always use localized strings** from the string catalog (`Resources/Localizable.xcstrings`)
- **Modern Swift 6 syntax:** Use static member syntax with `LocalizedStringResource`
- **Key format in catalog:** `{Feature}.{Context}.{type}` (e.g., `PhotoList.EmptyState.title`)
- **Example:**
  ```swift
  // ❌ Wrong - Hard-coded string
  Text("No photos available")

  // ❌ Wrong - Old style with string literal
  Text("PhotoList.EmptyState.title", bundle: .main)

  // ✅ Correct - Modern Swift 6 static member syntax
  Text(.photoListEmptyStateTitle)
  Button(.commonRetryLabel) {
      // action
  }
  ```
- **Note:** Hard-coded strings are acceptable in test code for readability

### File Organization
```
Photos/
├── Data/           # Infrastructure layer
│   ├── Models/     # DTOs (e.g., PhotoJSON)
│   ├── Networking/ # Network protocols
│   └── Repositories/ # Repository implementations
├── Domain/         # Business logic layer
│   ├── Models/     # Domain entities (e.g., Photo)
│   └── UseCases/   # Business logic coordination
├── UI/             # Presentation layer
│   ├── PhotoList/  # List feature
│   └── PhotoDetail/ # Detail feature
├── Mocks/          # Test doubles
└── Resources/      # Assets, localization
```

### Naming Conventions
- **ViewModels:** `{Feature}ViewModel` (e.g., `PhotoListViewModel`)
- **Views:** `{Feature}View` (e.g., `PhotoListView`)
- **Protocols:** `{Domain}{Type}` (e.g., `PhotoRepository`, `PhotoUseCase`)
- **Implementations:** `Default{Protocol}` (e.g., `DefaultPhotoRepository`)
- **Mocks:** `Mock{Protocol}` (e.g., `MockPhotoRepository`)

### Testing
- **Framework:** Swift Testing (not XCTest)
- **Syntax:** Use `@Test` attribute (not `func test...()`)
- **Assertions:** Use `#expect()` (not `XCTAssert`)
- **Async tests:** Mark with `async` and use `await`
- **MainActor tests:** Use `@MainActor @Test` for UI-related tests

### Localization
- **String catalog:** `Resources/Localizable.xcstrings`
- **Key format:** `{Feature}.{Context}.{type}`
  - Example: `Common.Retry.label`
  - Example: `PhotoList.EmptyState.title`

## Technology Stack
- **Language:** Swift 6.0
- **Minimum iOS:** 17.0+
- **UI Framework:** SwiftUI
- **Concurrency:** Swift Concurrency (async/await, actors)
- **Architecture:** Clean Architecture + MVVM + MVI (unidirectional data flow)
- **Testing:** Swift Testing framework
- **Networking:** URLSession with protocol abstraction
- **Dependency Injection:** Protocol-based with DIContainer

## Code Quality Standards

### Swift 6 Compliance
- All code must compile without warnings under strict concurrency checking
- No `@unchecked Sendable` without clear justification and documentation
- Proper actor isolation boundaries
- No force unwrapping in production code (acceptable in tests with justification)
- Error handling should preserve error context (avoid swallowing errors)

### Architecture Principles
- Dependency Inversion: UI depends on Domain, Domain depends on Data abstractions
- Single Responsibility: Each type has one clear purpose
- Protocol-based abstractions for testability
- Immutable value types preferred over mutable reference types
- ViewModels expose State and handle Actions (unidirectional flow)

## Custom Agents

### swift6-code-reviewer
Use this agent for comprehensive Swift 6 code reviews focusing on:
- Concurrency safety and data race prevention
- Actor isolation correctness
- Sendable conformance
- Modern iOS best practices

**When to use:** After completing a logical unit of work (new feature, significant refactor)

**Example:**
```
Use the swift6-code-reviewer agent to review my PhotoListViewModel implementation
```

## Important Notes for AI Assistants

### Standard Development Workflow

All development work should follow this three-stage workflow:

1. **Architect Agent** - Plans the implementation approach
   - Analyzes requirements and existing codebase
   - Designs the solution architecture
   - Details how the work should be done
   - Identifies potential issues and considerations
   - Provides a clear implementation plan

2. **Implementation** - Executes the plan
   - Follows the architectural guidance provided
   - Writes code according to project conventions
   - Creates tests for new functionality
   - Makes small, atomic commits
   - Ensures each commit compiles and passes tests

3. **Reviewer Agent** - Validates the implementation
   - Reviews all changes for correctness and quality
   - Checks Swift 6 concurrency compliance
   - Verifies adherence to project conventions
   - Identifies potential improvements or issues
   - Ensures tests adequately cover new functionality

**When to use this workflow:**
- All non-trivial feature implementations
- Significant refactoring or architectural changes
- Bug fixes that require design consideration
- Any work where planning would improve quality

**When you can skip it:**
- Trivial changes (typo fixes, formatting)
- Documentation updates
- Simple one-line bug fixes with obvious solutions

### When Making Changes
1. **Always read existing code** before suggesting changes to understand patterns
2. **Follow existing conventions** (naming, file structure, architecture)
3. **Maintain Swift 6 compliance** - no concurrency warnings allowed
4. **Preserve immutability** - use `let` for dependencies, avoid `var` where possible
5. **Don't add Sendable to protocols** unless there's a specific need (structs infer it automatically)
6. **ViewModels must be @MainActor** - this is already done, don't remove it
7. **Tests should not mutate ViewModels** after initialization
8. **Make small, atomic commits** - each commit should:
   - Compile successfully without errors or warnings
   - Include test coverage for any new or modified functionality
   - Represent a single logical change or unit of work
   - Be independently reviewable and revertable

### Common Patterns
- **ViewModel pattern:**
  ```swift
  @Observable
  @MainActor
  class FeatureViewModel {
      enum Action { ... }
      struct State: Equatable { ... }
      let useCases: UseCases
      var state: State

      func send(_ action: Action) async { ... }
  }
  ```

- **Repository pattern:**
  ```swift
  protocol FeatureRepository: Sendable {
      func fetch() async throws -> [Model]
  }

  struct DefaultFeatureRepository: FeatureRepository {
      let session: NetworkSession
  }
  ```

- **Use Case pattern:**
  ```swift
  protocol FeatureUseCase: Sendable {
      func execute() async throws -> Result
  }

  struct DefaultFeatureUseCase: FeatureUseCase {
      let repository: FeatureRepository
  }
  ```

### Recent Changes
- Switched from `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` to `nonisolated` (Nov 2024)
- All ViewModels already have explicit `@MainActor` annotations
- Data/Domain layers now correctly default to nonisolated
- PhotoJSON and other DTOs no longer need `nonisolated` annotations

## Additional Resources
- [Swift Evolution SE-0302](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md) - Sendable
- [Swift Evolution SE-0337](https://github.com/apple/swift-evolution/blob/main/proposals/0337-support-incremental-migration-to-concurrency-checking.md) - Concurrency Migration
- [Swift Evolution SE-0470](https://github.com/apple/swift-evolution/blob/main/proposals/0470-infer-isolated-conformances.md) - Isolated Conformances
