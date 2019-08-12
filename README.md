# gnimag - Gaming Reversed

Have you ever wanted to beat your friends' highscores in mobile games? Maybe without playing the game for hours and hours?

Well now you can! `gnimag` is a game-auto-player. It takes screen input from your mobile device, analyses it and simulates touches to play the game as far as possible.

Only a few games are implemented at the moment. You can help extending by contributing! (TODO: Link) As there is an [uncountable infinity](https://www.statista.com/statistics/780229/number-of-available-gaming-apps-in-the-google-play-store-quarter/) of mobile games out there, you can contribute very easily – just pick any game and start coding! See here(TODO) on how to start.

### Project Structure

The project consists of the following parts:

- Four base libraries (ImageInput, Tapping, ImageAnalysisKit and GameKit (TODO: jeweils links)). These provide required or useful tools for implementing your own game.
- The games. Each game is a library which provides a public entry point to start auto-playing the game.
- MacCLI. This is where actual Mac-specific input and output methods are defined. Here, you can import a specific game library and start playing the game.
- MacTestingTools. This library provides tools that are useful for testing while implementing a game or implementing methods in ImageAnalysisKit.

---

### Game Structure

See here(TODO) for how a game is built and how you can easily implement your own game.

---

### How do I install and run gnimag on my Mac?

TODO.

### What about iPhones?

Currently, there is no possibility to trigger touches on non-jailbroken iPhones. You could, however, build a tapping robot and use it as the `Tapper` that is provided to the specific games. Have fun building!

### Which games are currently implemented?

Fully implemented:

- ...

In progress:

- MrFlap ([App Store Link](https://apps.apple.com/at/app/mr-flap/id822206495); sadly no longer in the Play Store – APK available [here](https://apkpure.com/de/mr-flap/com.mrflap))