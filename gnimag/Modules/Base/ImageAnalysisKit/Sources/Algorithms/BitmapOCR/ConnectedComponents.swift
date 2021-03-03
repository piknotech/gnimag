//
//  Created by David Knothe on 23.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import Image

internal enum ConnectedComponents {
    enum ConnectivityType {
        /// Diagonal pixels are not considered neighbors.
        /// Each (non-edge) pixel has four neighbors.
        case four

        /// Diagonal pixels are considered neighbors.
        /// Each (non-edge) pixel has eight neighbors.
        case eight

        /// Return the neighbors of a given pixel.
        @_transparent
        func neighbors(for pixel: Pixel) -> [Pixel] {
            let x = pixel.x, y = pixel.y

            switch self {
            case .four:
                return [
                    Pixel(x-1, y), Pixel(x+1, y), Pixel(x, y-1), Pixel(x, y+1)
                ]
                
            case .eight:
                return [
                    Pixel(x-1, y), Pixel(x+1, y), Pixel(x, y-1), Pixel(x, y+1),
                    Pixel(x-1, y-1), Pixel(x-1, y+1), Pixel(x+1, y-1), Pixel(x+1, y+1)
                ]
            }
        }
    }

    /// Extract connected components from an image. Then, combine components using a combine decision function.
    /// The components are sorted left-to-right.
    static func `in`(_ image: Image, color: ColorMatch, connectivity: ConnectivityType, combineComponents: (OCRComponent, OCRComponent) -> Bool) -> [OCRComponent] {
        var components = connectedComponents(from: image, color: color, connectivity: connectivity)
        combine(components: &components, using: combineComponents)

        // Sort left-to-right
        components.sort { a, b in
            a.region.xRange.center < b.region.xRange.center
        }

        return components
    }

    /// Extract connected components from an image using depth-first search.
    private static func connectedComponents(from image: Image, color: ColorMatch, connectivity: ConnectivityType) -> [OCRComponent] {
        // Convert image to boolean bitmap
        let bitmap = (0 ..< image.width).map { x in
            (0 ..< image.height).map { y in
                color.matches(image.color(at: Pixel(x, y)))
            }
        }

        // Labels partitioning the pixels into components; 0 means background pixel (i.e. bitmap[x][y] = false)
        var labels = [[Int]](repeating: [Int](repeating: 0, count: image.height), count: image.width)

        // Depth-first search
        func dfs(pixel p: Pixel, label: Int) {
            guard image.contains(p) else { return }
            if labels[p.x][p.y] != 0 || !bitmap[p.x][p.y] { return }

            labels[p.x][p.y] = label
            for neighbor in connectivity.neighbors(for: p) {
                dfs(pixel: neighbor, label: label)
            }
        }

        // Perform search
        var component = 1

        for x in 0 ..< image.width {
            for y in 0 ..< image.height {
                if labels[x][y] == 0 && bitmap[x][y] {
                    dfs(pixel: Pixel(x, y), label: component)
                    component += 1
                }
            }
        }

        // Extract components (as pixel arrays) from label bitmap
        var components = [Int: [Pixel]]()

        for x in 0 ..< image.width {
            for y in 0 ..< image.height {
                let pixel = Pixel(x, y), label = labels[x][y]
                if label != 0 {
                    components[label] ??= []
                    components[label]!.append(pixel)
                }
            }
        }

        // Convert pixel arrays to OCRComponents
        return components.values.map { pixels in
            OCRComponent(pixels: pixels)
        }
    }

    /// Combine components using a combine decision function.
    private static func combine(components: inout [OCRComponent], using shouldCombine: (OCRComponent, OCRComponent) -> Bool) {
        /// Combine two components and re-iterate through the beginning of the list to check if the new combination caused a valid combination with an earlier component (which would lead to recursive combinations).
        /// Return the index where the outer loop should continue (i.e. the smallest component that has been affected).
        func combine(_ i: Int, _ j: Int) -> Int {
            let smaller = min(i, j), larger = max(i, j)
            components[smaller] = components[smaller].combine(with: components.remove(at: larger))

            for j in 0 ..< smaller {
                if shouldCombine(components[i], components[j]) {
                    return combine(i, j)
                }
            }

            return smaller
        }

        var index = 0

        // Try combining each component with each other one
        outer: while index < components.count {
            for j in index + 1 ..< components.count {
                // Try (recursively) combining components
                if shouldCombine(components[index], components[j]) {
                    index = combine(index, j)
                    continue outer
                }
            }

            // No combination: next component
            index += 1
        }
    }
}
