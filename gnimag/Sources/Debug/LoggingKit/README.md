# LoggingKit

`LoggingKit` builds on `TestingTools` to provide automated logging capabilities. Use LoggingKit in your game to receive automatic logging of your current game state when a part of your game logic fails. This can include image analysis, game model collection or tap prediction – when setup correctly, LoggingKit helps to you track down and eliminate all kinds of specific and hard-to-find errors.

The idea behind `LoggingKit` is the following:

- You create your own `DebugLogger` and `DebugLoggerFrame` classes, deriving from protocols/classes from `LoggingKit`. DebugLoggerFrame should contain as many information about your current frame as possible.
- In your game logic (image analysis, game model collection etc.), you fill all properties of your DebugLoggerFrame. When errors / integrity failures occur, you also inform the DebugLoggerFrame about this.
- Logging Step: You provide methods deciding if a DebugLoggerFrame is important, and if yes, how it should be logged. Logging can include images (using `BitmapCanvas` or `ScatterPlot` from `TestingTools`) and textual representation of the game state.

LoggingKit provides suitable tools to easily obtain and plot debug information from trackers.