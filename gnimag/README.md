Here lives the Xcode project.

The project uses Swift 5.1; you need Xcode 11 for building and running gnimag.

All libraries are defined as targets. Dependencies are managed via [Accio](https://github.com/JamitLabs/Accio). Call `accio update` to fetch dependencies.

Currently, building all targets simultaneously does not work due to an Xcode bug. Therefore, you must build all targets manually. Therefore, select the according scheme and build it. Do this iteratively until reaching MacCLI, the highest-level module.

This is the module graph:
TODO
