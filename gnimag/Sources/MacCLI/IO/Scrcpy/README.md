# Scrcpy

Scrcpy is an application that can stream your Android device onto your Mac desktop. Also, scrcpy can send input events to the Android device. This makes it perfect for our use-case.

You can download scrcpy [here](https://github.com/Genymobile/scrcpy).

The `Scrcpy` class bundles this functionality by providing `IImageProvider` and `ITapper`. When using it, scrcpy must already be running and streaming your device.