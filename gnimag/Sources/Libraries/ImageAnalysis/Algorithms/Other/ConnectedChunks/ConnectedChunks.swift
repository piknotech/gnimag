//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

public enum ConnectedChunks {
    /// Defines a chunk of objects.
    public struct Chunk<T: DistanceMeasurable> {
        public private(set) var objects: [T]

        /// The maximum distance between any of the objects in the chunk.
        public private(set) var diameter: Double = 0

        /// Initialize the chunk with the given objects. Calculate the diameter in O(n^2).
        init(objects: [T]) {
            self.objects = objects

            // Calculate maximum distance between any two points, requiring O(n^2) in total
            var remaining = objects
            while remaining.count > 1 {
                let first = remaining.removeFirst()
                diameter = max(diameter, ConnectedChunks.maxDistance(from: first, to: remaining))
            }
        }

        /// Add an object to the collection and update the diameter, if required.
        mutating func add(_ object: T) {
            diameter = max(diameter, ConnectedChunks.maxDistance(from: object, to: objects))
            objects.append(object)
        }
    }

    /// The result of a split-into-connected-chunks algorithm.
    public struct Result<T: DistanceMeasurable> {
        let chunks: [Chunk<T>] // The chunks, sorted by size.
        let maxChunkSize: Int
        let maxChunkDiameter: Double
    }

    /// Split an array of objects into connected chunks. Return all chunks, sorted by their size.
    /// In each chunk, any two objects are connected via a path; in this path, all two consecutive objects are apart by not more than "maxDistance".
    /// This means that, in any chunk, there could be objects with an arbitrary distance – as long as they are connected with a path as described above.
    /// This function runs in O(n^2).
    public static func from<T: DistanceMeasurable>(_ input: [T], maxDistance: Double) -> Result<T> {
        var chunks = [Chunk<T>]()

        for object in input {
            var matchingChunkIndices = [Int]()

            // Check for each chunk if the object is near enough
            for (index, chunk) in chunks.enumerated() {
                for existing in chunk.objects {
                    if object.distance(to: existing) <= maxDistance {
                        matchingChunkIndices.append(index)
                    }
                }
            }

            // Merge the new object and all matching chunks
            switch matchingChunkIndices.count {
            case 0:
                chunks.append(Chunk(objects: [object]))
            case 1:
                chunks[matchingChunkIndices.first!].add(object)
            default:
                // Remove all matching chunks and add a single new one
                let all = matchingChunkIndices.reversed().reduce([]) { array, index in
                    chunks.remove(at: index).objects
                } + [object]
                chunks.append(Chunk(objects: all))
            }
        }

        // Sort chunks by size and return result
        chunks.sort { $0.objects.count > $1.objects.count }
        return Result(
            chunks: chunks,
            maxChunkSize: chunks.first?.objects.count ?? 0,
            maxChunkDiameter: chunks.map { $0.diameter }.max() ?? 0
        )
    }

    /// Calculate the maximum distance of an object to an array of other objects.
    /// This requires O(n) time.
    private static func maxDistance<T: DistanceMeasurable>(from object: T, to others: [T]) -> Double {
        others.map(object.distance(to:)).max() ?? 0
    }
}
