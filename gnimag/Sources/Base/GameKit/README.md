# GameKit

GameKit contains useful tools for implementing a game. These tools are especially useful for the steps of game model collection and tapping prediction.

Currently, these tools are:

- `Tracker`s: Trackers take time-value pairs and provide a matching regression function, for example a linear or quadratic curve. These can be used to continuously extract and update physical game parameters, such as player speed (using a linear curve) or the environmental gravity (quadratic curve).

You are welcome to contribute and extend GameKit with more useful tools!
