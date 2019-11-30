# ImageAnalysisKit

ImageAnalysis contains useful tools for simple image analysis. This means, it is useful for simple games that consist of little different colors and do not require very complex image analysis.

ImageAnalysisKit contains a multitude of alogrithms, for example:

- Object contour detection using a known point inside the object (`ContourDetectionViaEquidistantRays`)
- Splitting a bunch of `Pixel`s or `Color`s into clusters that are each connected amongst themselves (`SimpleClustering`)
- Smallest enclosing shapes (circle, polygon, axis-aligned bounding box, oriented bounding box) from a set of `Pixel`s (`SmallestCircle`, `ConvexHull`, `SmallestAABB`, `SmallestOBB`)

You are welcome to contribute and extend ImageAnalysis with more useful tools and algorithms!

**Important**: Any coordinate systems in this module area `LLO` ("lower-left origin"), meaning that the origin is in the lower-left corner and the coordinate axes extend upwards and to the right.
