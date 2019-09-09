This directory contains all fully implemented games.

This README contains information about how games are built and **gives a starting point for you on how to implement your own game**.

## Structure of a Game

The structure of most games is similar. A game consists of three parts: image analysis, game model construction and tapping prediction.

- **Image Analysis**: Here, you provide a method that has an `Image` as input and outputs raw information about things that were found in the image, for example player positions, background color, and any relevant game data you need.

  `ImageAnalysisKit` helps with simple analysis tasks. You may be able to do most of the analysis with methods provided by ImageAnalysisKit. If not, you are welcome to contribute and extend ImageAnalysisKit itself(LINK).

  You do not further process the analysed data in this step. Also, your image analysis class should not save any state. Any input parameters (like starting points for object search) should be provided by game model construction or tapping prediction.

- **Game Model Construction**: here, you take the information provided by image analysis and use it to build and update an up-to-date game model. This game model contains any parameters and values that you need to fully comprehend the running game, for example player positions or physics values.

  When receiving data from the image analysis step, first check for data integrity, i.e. if all measured values are approximately what they should be. When data is obviously invalid, the image analysis yielded wrong values – discard the data and hope that the next data frame is valid again.

  A very useful tool for checking for integrity and then storing and processing data are `Tracker`s (from `GameKit`). Trackers take time-value pairs and provide a matching regression function, for example a linear or quadratic curve. These can be used to continuously extract and update physical parameters, such as player speed (using a linear curve) or the environmental gravity (quadratic curve).

  All in all, you update the game model and calculate physics and game-related parameters, but do not process them further.

- **Tapping Prediction**: here, you take the game model and schedule future taps. You think about what sequence of taps you need to survive the current game situation, and schedule or reschedule the taps accordingly. Also, do you keep track of Time Delay? Oder woanders?

Having these three independent components, you can finally create your public `Game` class. It requires `ImageProvider` and `Tapper` instances which will be provided by the user of the game library (for example `MacCLI`).

You can use an `ImageQueue` (`GameKit`) for simple asynchronous image processing; i.e., each time a new frame is available (e.g. at a rate of 60fps), the work of image analysis, game model construction and tapping prediction is done in the background, but still at a high priority.

The Game directs the output from image analysis to game model construction, and feeds the data from game model construction into tapping prediction.

Also, the Game provides events which may be of interest to the user, like „level finished“, „point scored“, or „player died“.

---

As a good and simple starting point, we suggest you to look at [MrFlap](MrFlap), which is a simple game in most aspects. Try understanding the exact structure and logic; it is not very hard.

TODO: code examples

---

## Other Aspects

### Hardcoding

What about hardcoding game parameters like colors, absolute or relative pixel sizes of game objects or physics values like speed or gravity?

Try avoiding it wherever possible.

Instead, you „hardcode“ information and logic, for example:

- You know that the player speed stays constant all the time. This would allow you to use a ConstantTracker for the speed, or better, a LinearTracker for the player position. But do not hardcode the speed value as it is most likely dependent on screen size and difficulty level.
- You know that the background color is always the same. Instead of hardcoding it, read it once (e.g. from the first image that is analyzed) and store it from thereon.

To summarize: use Trackers to calculate physics values and game parameters. Try not to hardcode specific colors but read them from the images, if possible.



### Input/Output Delay

A very important thing to think about is input/output delay.

Any tool you use for transferring the screen content from your mobile device to your computer, like [scrcpy](../Mac/MacCLI/Sources/IO/Scrcpy), has a small, but noticeable input delay. Depending on what you use for tapping, there may arise an additional output delay.

Your game must of course make up for this delay. Anything your program sees is slightly in the past. You want to calculate the **current**, live game model and use this to make tap predictions.

This can, for example, be done using Trackers. If you feed your game model values in sensible Trackers, you get a useful time-value curve, which you can use to calculate the value for future times (for example `now + 0.3s`). You can convince yourself that it is necessary to use the combined delay, which is the sum of the input and output delay.

There is a simple way to determine this delay: TODO.



### What About OpenCV For Image Analysis?

If you want to use OpenCV or similar libraries, keep in mind that gnimag is a live tool: your game should be able to process images at a frame rate of up to 60fps.

`ImageAnalysisKit` is a good tool for simple games which consist of little different colors and that do not require very complex image analysis. If all relevant game objects are clearly distinguishable just by their colors, you may be well served by `ImageAnalysisKit`. Look at the `MrFlap` implementation – it provides a good example of how to use `ImageAnalysisKit` for simple tasks (MrFlap consists of just two different relevant colors).

In the end, is up to your preferences which library you use, while `ImageAnalysisKit` is preferred when possible. You are welcome to contribute to `ImageAnalysisKit`! There are always things that are still missing and waiting to be implemented.



### How Do I Start Implementing a New Game?

Have a look at the code of [MrFlap](MrFlap). It is a simple and well-documented example of a working game. Then, try sticking to the principles outlined in this document and start coding!

If you have any questions, please ask, we’re here to help. Contact [@knothed](https://github.com/knothed) via email or write a question on GitHub.
