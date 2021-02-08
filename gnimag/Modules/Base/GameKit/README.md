# GameKit

GameKit contains useful tools for implementing a game. These tools are especially useful for the steps of game model collection and tapping prediction.
In contrast, for the image analysis step, `ImageAnalysisKit` is the suitable toolkit.

Currently, these tools are:

- `Tracker`s: Trackers take time-value pairs and provide a matching regression function, for example a linear or quadratic curve. These can be used to continuously extract and update physical game parameters, such as player speed (using a linear curve) or the environmental gravity (quadratic curve).
- In addition to the various trackers, GameKit provides tools for visualization: drawing a `ScatterPlot` containing the tracker's data points, regression curves and tolerance region boundary curves.
- `GameQueue` and `Tapping` tools: Tools which are required for building the foundation of a classical 3-step game structure with image analysis, game model collection and tap prediction.
- Auxiliary tools inlcuding various arithmetic/mathematic tools, and some `ScatterStrokables`, which allow drawing functions onto a `ScatterPlot`.

You are welcome to extend GameKit with more useful tools!
