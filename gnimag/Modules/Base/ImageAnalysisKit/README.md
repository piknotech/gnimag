# ImageAnalysisKit

`ImageAnalysisKit` contains useful tools for simple image analysis. This means, it is useful for simple games that consist of little different colors and do not require very complex image analysis.

`ImageAnalysisKit` contains a multitude of various algorithms, for example:

- Object edge detection using a known point inside the object (`EdgeDetector`, `RayShooter`)
- Splitting a bunch of `Pixel`s or `Color`s into clusters that are each connected amongst themselves (`SimpleClustering`)
- Smallest enclosing shapes (circle, polygon, axis-aligned bounding box, oriented bounding box) from a set of `Pixel`s (`SmallestCircle`, `ConvexHull`, `SmallestAABB`, `SmallestOBB`)
- Other stuff based on `ColorMatch` and `PixelPath`.

You are welcome to contribute and extend ImageAnalysis with more useful tools and algorithms!

**Important**: Any coordinate systems in this module area `LLO` ("lower-left origin"), meaning that the origin is in the lower-left corner and the coordinate axes extend upwards and to the right.
