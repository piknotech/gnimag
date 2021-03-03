# GameKit

GameKit contains various tools which are very useful for implementing a game.

These tools are especially powerful for the steps of game model collection and tapping prediction. In contrast, for the image analysis step, `ImageAnalysisKit` is the suitable toolkit.

These tools include:

- `GameQueue`: Powers and manages the real-time frame-by-frame analysis process. Every time a new image arrives, `GameQueue` executes your analysis callback on a high-priority queue.
- `Trackers`: Use the powerful `SimpleTrackers` and `CompositeTrackers` to track all kinds of physical relations within the game (e.g. player movement, jumping) and to determine the exact parameters of the physical environment over time (e.g. player speed or acceleration, gravity and jump velocity).
- `TapScheduler`: While you calculate and continuously update the optimal tap sequence, `TapScheduler` performs the scheduled taps and keeps track of the input+output delay.

- Many more auxiliary tools inlcuding some mathematic tools and some `ScatterStrokables` which allow drawing mathematical functions onto images.
