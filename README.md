# gnimag - Gaming Reversed

Have you ever wanted to beat your friends' highscores in mobile games? Maybe without playing the game for hours and hours?

Well now you can! `gnimag` is a game-auto-player. It takes screen input from your mobile device, analyses it and simulates touches to play the game as far as possible.

Only a few games are implemented at the moment. You can help extending by [contributing](gnimag/Sources/Games)! As there is an [uncountable infinity](https://www.statista.com/statistics/268251/number-of-apps-in-the-itunes-app-store-since-2008/) of mobile games out there, you can contribute very easily – just pick any game and start coding! See [here](gnimag/Sources/Games) on how to start.

## Project Structure

The project consists of the following parts:

- Six base libraries ([Common](gnimag/Sources/Base/Common), [Geometry](gnimag/Sources/Base/Geometry), [Image](gnimag/Sources/Base/Image), [Tapping](gnimag/Sources/Base/Tapping), [ImageAnalysisKit](gnimag/Sources/Base/ImageAnalysisKit) and [GameKit](gnimag/Sources/Base/GameKit)). These provide required and useful tools for implementing your own game.
- Two debugging and logging libraries ([TestingTools](gnimag/Sources/Debug/TestingTools) and [LoggingKit](gnimag/Sources/Debug/LoggingKit).) They provide tools for manual and automated testing and logging while implementing a game.
- [The games](gnimag/Sources/Games). Each game is a library which provides a public entry point to start auto-playing the game.
- [gnimag](gnimag/Sources/Products/gnimag). The executable which allow running gnimag. Also, the actual Mac-specific input and output methods are defined here.

---

## Game Structure

See [here](gnimag/Sources/Games) for how a game is built and how you can easily implement your own game.

---

### How do I install and run gnimag on my Mac?

Call `make install` to build and install gnimag. You need [Accio](https://github.com/JamitLabs/Accio) for dependency resolution.

After `make install`, use `gnimag` to start gnimag.

### What about iPhones?

Currently, there is no possibility to trigger touches on non-jailbroken iPhones. You could, however, build a tapping robot and use it as the `Tapper` that is provided to the specific games. Have fun building!

### Which games are currently implemented?

Fully implemented:

- ...

In progress:

- [MrFlap](gnimag/Sources/Games/MrFlap) ([App Store Link](https://apps.apple.com/at/app/mr-flap/id822206495); sadly no longer in the Play Store – APK available [here](https://apkpure.com/de/mr-flap/com.mrflap))