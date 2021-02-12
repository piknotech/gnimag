# ImageAnalysisKit

ImageAnalysisKit contains useful tools for low-level analysis of simple images.

ImageAnalysisKit contains a multitude of various algorithms, for example:

- Object edge detection using a known point inside the object (`EdgeDetector`, `RayShooter`)
- Splitting a bunch of `Pixel`s or `Color`s into clusters that are each connected amongst themselves (`SimpleClustering`)
- Smallest enclosing shapes (circle, polygon, axis-aligned bounding box, oriented bounding box) from a set of `Pixel`s (`SmallestCircle`, `ConvexHull`, `SmallestAABB`, `SmallestOBB`)
- `BitmapOCR` to read text from images, and many more.

You are welcome to contribute and extend ImageAnalysis with more useful tools and algorithms!

**Important**: Any coordinate systems in this module are `LLO` (_lower-left origin_), meaning that the origin is in the lower-left corner and the coordinate axes extend upwards and to the right.