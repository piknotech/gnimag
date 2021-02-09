# Tutorial

_How to get, setup and run gnimag_



## 0. What do you need?

1. You need a Mac: _gnimag_ is written in Swift and does therefore only run on macOS. (_gnimag_ uses Cocoa in some minor places. These places would have to be rewritten for Linux in order for _gnimag_ to compile and run on Linux/Unix etc.).

2. [Xcode 12](https://apps.apple.com/us/app/xcode/id497799835?mt=12) needs to be installed on your Mac. You also need [brew](https://brew.sh) and [make](https://formulae.brew.sh/formula/make).

3. With these prerequisuites, all you need is an Android smartphone (or Windows Phone) to get started. If you want to run _gnimag_ on an iPhone, you need to build a tapping robot (there are some tutorials out there that build an Arduino-driven robot). This is because iPhones don't allow touch simulation via software.



## 1. Getting _gnimag_

1. [Download](https://github.com/piknotech/gnimag/archive/stable.zip) or clone this repository from GitHub.
2. Select the folder in terminal and execute `make`.
3. Wait a few minutes while `make` is building _gnimag_ from source.



## 2. Setup the enivronment

You need a program for mirroring your smartphone to your computer.

- For Android devices, we recommend [_scrcpy_](https://github.com/Genymobile/scrcpy).
- For iPhones, we recommend [AirServer](https://www.airserver.com/Mac). It is paid but has a free trial version.

After installing the screen mirroring program, connect your smartphone **via cable** to your Mac and start mirroring the screen.

- On Android, make sure you have [enabled adb debugging](https://developer.android.com/studio/command-line/adb.html#Enabling) on your device.
- For a more stable AirServer-iPhone connection:
  - Before starting AirServer, disable both iPhone's and Mac's WLAN and Bluetooth.
  - Plug your iPhone into your Mac. Create a personal hotspot on your iPhone and connect your Mac to this hotspot (inside the Mac's network settings).
  - This allows AirPlay transmission via cable rather than via WLAN.



## 3. Running _gnimag_

After `make` has finished successfully, press _play_ in MrFlap. Then start `gnimag`:

```
gnimag run mrflap -android
gnimag run mrflap -ios
```

See here (or run `gnimag`) for all supported games.

---

Stop _gnimag_ by pressing `alt+c` in the Terminal.

**Attention:** While running `gnimag`, use your Mac as little as possible. _gnimag_ takes plenty of resources as it continuously fetches new images from the screen mirroring application (at the Mac screen refresh rate) and analyzes them. In fact, closing, hiding or moving the screen mirroring application's window may adversely affect or stop _gnimag_.