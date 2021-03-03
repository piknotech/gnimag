# LoggingKit

Use `LoggingKit` in your game to perform automatic logging of relevant frames. When setup correctly, LoggingKit helps to you track down and eliminate all kinds of specific and hard-to-find errors.

The idea behind `LoggingKit` is the following:

- You create your own `DebugLogger` and `DebugLoggerFrame` classes, deriving from protocols/classes of`LoggingKit`. DebugLoggerFrame should contain as many information about your current frame as possible.
- In your game logic (image analysis, game model collection etc.), you fill all properties of your DebugLoggerFrame. When errors / integrity failures occur, you also inform the DebugLoggerFrame about this.
- Logging Step: You provide methods deciding if a DebugLoggerFrame is important, and if so, how and what should be logged. Logging can include images (using `BitmapCanvas` or `ScatterPlot` from `TestingTools`) and textual representation of the game state.

LoggingKit also provides suitable tools to easily obtain and plot debug information from trackers.

