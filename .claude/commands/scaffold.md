---
description: Add Clean Architecture scaffolding to an existing iOS project
---

You are tasked with adding Clean Architecture scaffolding to an existing barebone iOS project.

## Instructions

1. **Verify the current project:**
   - Confirm you're in an Xcode project directory
   - Identify the main app target name (usually matches the project name)
   - Locate the existing app source directory

2. **Read the ARCHITECTURE.md file** from /Users/adam/Projects/iOS/Directory/ARCHITECTURE.md to understand the full architectural pattern.

3. **Create the Clean Architecture directory structure** in the existing project:

```
{AppName}/
├── {AppName}App.swift          # Usually already exists
├── DIContainer.swift           # CREATE
├── Domain/                     # CREATE
│   ├── Models/
│   └── UseCases/
├── Data/                       # CREATE
│   ├── Repositories/
│   ├── Models/
│   └── Networking/
│       └── NetworkSession.swift
├── UI/                         # CREATE
│   └── Shared/
├── Mocks/                      # CREATE
│   └── Responses/
└── Resources/                  # May already exist
    ├── Assets.xcassets/        # Usually already exists
    └── Localizable.xcstrings   # CREATE if doesn't exist
```

4. **Create the test directory structure:**

```
{AppName}Tests/
├── Domain/
│   └── UseCases/
├── Data/
│   └── Repositories/
└── UI/
```

5. **Create core infrastructure files:**

   **DIContainer.swift:**
   ```swift
   // DIContainer.swift

   // Compose all use case protocols
   typealias AllUseCases = EmptyUseCases // Replace when adding first use case

   struct DIContainer: AllUseCases {
       // Add use cases here as you build them
   }

   extension DIContainer {
       // Production configuration
       static func real() -> DIContainer {
           // Build dependency graph from bottom up
           return DIContainer()
       }

       // Mock configuration for tests/previews
       static func mock() -> DIContainer {
           DIContainer()
       }
   }

   // Placeholder protocol - remove when adding first real use case
   protocol EmptyUseCases { }
   ```

   **Data/Networking/NetworkSession.swift:**
   ```swift
   // Data/Networking/NetworkSession.swift
   import Foundation

   protocol NetworkSession {
       func data(for request: URLRequest) async throws -> (Data, URLResponse)
   }

   extension URLSession: NetworkSession { }
   ```

   **Mocks/MockNetworkSession.swift:**
   ```swift
   // Mocks/MockNetworkSession.swift
   #if DEBUG
   import Foundation

   struct MockNetworkSession: NetworkSession {
       var throwError: Bool = false
       var statusCode: Int = 200
       var responseFileName: String = "mockResponse"

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

   enum MockError: Error {
       case mockError
   }
   #endif
   ```

   **Resources/Localizable.xcstrings** (if doesn't exist):
   ```json
   {
     "sourceLanguage" : "en",
     "strings" : {
       "Common.Retry.label" : {
         "extractionState" : "manual",
         "localizations" : {
           "en" : {
             "stringUnit" : {
               "state" : "translated",
               "value" : "Retry"
             }
           }
         }
       }
     },
     "version" : "1.0"
   }
   ```

6. **Update the App entry point** to use DIContainer:
   - Read the existing `{AppName}App.swift`
   - Add `private let container = DIContainer.real()` property
   - Update to pass container to root view when use cases are added

7. **Create a .gitignore** if it doesn't exist:
   ```
   # Xcode
   build/
   DerivedData/
   *.pbxuser
   !default.pbxuser
   *.mode1v3
   !default.mode1v3
   *.mode2v3
   !default.mode2v3
   *.perspectivev3
   !default.perspectivev3
   xcuserdata/
   *.xccheckout
   *.moved-aside
   *.xcuserstate

   # Swift Package Manager
   .build/
   .swiftpm/

   # CocoaPods
   Pods/

   # macOS
   .DS_Store
   ```

8. **Copy ARCHITECTURE.md** to the new project for reference

9. **Create a README.md** explaining:
   - The architecture being used
   - Reference to ARCHITECTURE.md for details
   - How to add the first feature
   - Next steps

10. **Add files to Xcode project:**
    - Use `xcodebuild` or provide instructions for manually adding files
    - Ensure files are added to the correct target
    - Organize files in Xcode groups matching folder structure

11. **Report what was created:**
    - List all directories created
    - List all files created
    - Provide next steps for adding first feature
    - Suggest any Xcode build settings to configure

## Key Points

- **Don't delete or modify** existing files unless necessary (like updating the App entry point)
- **Preserve existing structure** - only add the Clean Architecture scaffolding
- **Use protocol-oriented design** from the start
- **Follow naming conventions** from ARCHITECTURE.md
- **Create placeholder protocols** that can be replaced as features are added
- **Ensure all mocks are wrapped in `#if DEBUG`** blocks

## After Scaffolding

Provide the user with:
1. Summary of what was created
2. Instructions for adding their first feature (use ARCHITECTURE.md as guide)
3. Recommend Xcode build settings to configure:
   - Swift Concurrency: Enabled
   - Approachable Concurrency: YES
   - Default Actor Isolation: MainActor
   - Enable Previews: YES
   - String Catalog Generation: YES
