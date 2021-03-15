//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

public protocol HasDistance {
    /// Calculate the distance to another object of the same type.
    /// This distance must always be >= 0.
    func distance(to other: Self) -> Double
}

public enum SimpleClustering {
    /// Defines a cluster of objects.
    public class Cluster<T: HasDistance>: CustomStringConvertible {
        public private(set) var objects: [T]

        /// The number of objects in the cluster.
        public var size: Int { objects.count }

        /// The maximum distance between any of the objects in the cluster.
        /// Is nil until explicitly calculated by calling `updateDiameter`.
        public private(set) var diameter: Double?

        /// As clusters are never empty, this returns any object in the cluster.
        public var any: T { objects.first! }

        /// Initialize the cluster with the given objects (at least one). Calculate the diameter in O(n^2).
        /// `objects` may not be empty!
        init(objects: [T]) {
            self.objects = objects
        }

        /// Add an object to the collection; do not update the diameter.
        func add(_ object: T) {
            objects.append(object)
        }

        /// Calculate and fill `diameter`.
        /// Takes O(n^2) time.
        public func updateDiameter() {
            diameter = 0

            // Calculate maximum distance between any two points, requiring O(n^2) in total
            var remaining = objects
            while remaining.count > 1 {
                let first = remaining.removeFirst()
                let maxDistance = remaining.map(first.distance(to:)).max() ?? 0
                diameter = max(diameter!, maxDistance)
            }
        }

        public var description: String {
            "Cluster(size: \(size), diameter: \(String(describing: diameter)), any: \(any))"
        }
    }

    /// The result of a split-into-connected-clusters algorithm.
    /// Until calling `calculateClusterDiameters`, the cluster diameters are nil.
    public struct Result<T: HasDistance> {
        public let clusters: [Cluster<T>] // The clusters, sorted by size.
        public var largestCluster: Cluster<T> { clusters.first! }
        public var largestDiameter: Double? { clusters.compactMap(\.diameter).max() }

        /// Calculate and fill `diameter` for each cluster.
        /// Takes O(n^2) time.
        public func calculateClusterDiameters() {
            clusters.forEach { $0.updateDiameter() }
        }
    }

    /// Split an array of objects into connected clusters. Return all clusters, sorted by their size.
    /// In each cluster, any two objects are connected via a path; in this path, all two consecutive objects are apart by not more than "maxDistance".
    /// This means that, in any cluster, there could be objects with an arbitrary distance – as long as they are connected with a path as described above.
    /// This function runs in O(n).
    public static func from<T: HasDistance>(_ input: [T], maxDistance: Double) -> Result<T> {
        var clusters = [Cluster<T>]()

        for object in input {
            var matchingClusterIndices = [Int]()

            // Check for each cluster if the object is near enough
            clusters: for (index, cluster) in clusters.enumerated() {
                for existing in cluster.objects {
                    if object.distance(to: existing) <= maxDistance {
                        matchingClusterIndices.append(index)
                        continue clusters
                    }
                }
            }

            // Merge the new object and all matching clusters
            switch matchingClusterIndices.count {
            case 0:
                clusters.append(Cluster(objects: [object]))
            case 1:
                clusters[matchingClusterIndices.first!].add(object)
            default:
                // Remove all matching clusters and add a single new one
                let all = matchingClusterIndices.reversed().reduce([]) { array, index in
                    clusters.remove(at: index).objects
                } + [object]
                clusters.append(Cluster(objects: all))
            }
        }

        // Sort clusters by size and return result
        clusters.sort(by: \.objects.count)
        return Result(clusters: clusters)
    }
}
