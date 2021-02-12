# Image

Image defines base classes like `Image`, `Pixel` and `Color` and exposes an `ImageProvider` protocol.

While concrete image sources like a window content source implement the `ImageProvider` protocol, games only communicate with abstract `ImageProvider`s. The _gnimag_ user can then use their `ImageProvider` of choice for any game they like.