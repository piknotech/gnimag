# Image

Image both defines base classes like `Image`, `Pixel` and `Color` and exposes an `ImageProvider` protocol. This protocol must be implemented by your hosting application – all games need a concrete instance of `ImageProvider` which updates them with live images from the mobile device.

For example, MacCLI provides an `AppWindowImageProvider`, which just continuously fetches and forwards the contents of a macOS window, at a framerate of 60fps.
