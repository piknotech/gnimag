Here lives the Xcode project.

The project uses Swift 5.1; you need Xcode 11 for building and running gnimag.

Currently, the project is managed using SwiftPM. All libraries are defined as different targets in [Package.swift](./Package.swift).

To start, create an xcodeproj with `swift package generate-xcodeproj`. Then call `swift package update` to fetch dependencies. Then, you can select the `MacCLI` scheme in Xcode and build or run it.