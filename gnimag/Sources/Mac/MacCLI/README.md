# MacCLI

MacCLI is a simple command line tool to allow testing and executing games. It provides macOS-specific implementations for `Image`, `ImageProvider` and `Tapper`.

Use MacCLI it for the development of your game or just to start a game that you would like to play.

To start a game, just import the according game library into main.swift, create an instance of the game and call `play()` (or something like that)!

To play a game on an android device, you need [scrcpy](Sources/IO/Scrcpy). Use scrcpy to mirror the device to your Mac. Open the game and you can start playing as described above.

iOS devices are not supported.
