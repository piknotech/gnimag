# Developing _gnimag_

This document covers several things you should know while developing on _gnimag_.



## Modularisation

_gnimag_ is partitioned into several different modules. For example, each game is implemented as a new stand-alone module. Read more about it [here](Modularisation.md).

## Build Settings

_gnimag_ needs to run on highest optimization level (at least for highly resource-intensive games like _MrFlap_), otherwise _gnimag_ can't keep up with analysing 60 frames per second in real-time.

Therefore, we compile all modules in release mode per default and use `-Ounchecked` and _Disable Safety Checks_.

## Building

There are two ways to build _gnimag_: via Xcode and via `make`. We want to support both build variants equally: Xcode for development and `make` for distribution.

Both build variants should produce very similar products – we use the same build settings for both variants. When you build via Xcode, use the `All` scheme. It contains and builds all modules consecutively.

We use `swift build` inside the Makefile. `swift build` is more strict regarding import statements, so be sure to import all frameworks you use (even `Foundation`), else `make` will complain.

Before creating a pull request, always test whether your code still builds (and works) with `make`.

## Dependencies

We use the integrated Swift Package Manager to manage external dependencies within Xcode. For building with `make` (i.e. `swift build`), we need a `Package.swift` however. This `Package.swift` also describes all (external and internal) dependencies, but is not used when building via Xcode.

When you add a dependency or create a new module in Xcode, be sure to also update the `Package.swift` file.

## Creating a New Module

You create a new module when creating a new game or creating a new library. In these cases, there is a ModuleTemplate module which you can duplicate and rename. Then, you still have to:

+ Change the bundle identifier (to `com.piknotech.gnimag.module_name`)
+ Create a scheme for the module **and** add the module to the `All` scheme
+ Add the module and all new inter-module dependencies to `Package.swift`
+ Organize the module and its files (`Info.plist` and `Module-Header.h`) in a directory structure, the same way as the other modules are organized (subfolders: _Sources_, _SupportingFiles_, _Resources_ (optional)).