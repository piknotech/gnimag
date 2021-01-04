## Android

You can use [scrcpy](https://github.com/Genymobile/scrcpy) or [vysor](https://vysor.io) to both stream and interact with your Android device on your Mac desktop. The Android device screen will be mirrored onto a window on your Mac. Tapping on the window will produce a tap on the Android device. 

## iOS

Using [AirServer](https://www.airserver.com) or QuickTimePlayer, you can mirror your iPhone to your Mac using a USB cable.
In contrast to Android devices, iOS devices do not allow touches to be created from outside. Therefore, these applications can only be used for screen input, and tap output must be done using a tap robot.

We recommend AirServer because of its small average input delay (around 0.12s). QuickTimePlayer has a delay of ~0.25s.

When connecting your iPhone to AirServer, make sure to first disable both iPhone's and Mac's WLAN and Bluetooth. Then create a hotspot on your iPhone and connect your Mac to this hotspot (inside the Mac's Network settings). This allows AirPlay transmission via cable.

You can also connect your iPhone to AirServer via WLAN - this makes the connection more instable. 
