//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Input

/// LimitedPath allows paths to be limited to a certain number of pixels after which they should stop.

public struct LimitedPath: PixelPath {
    /// The path that is being limited.
    public var path: PixelPath

    /// The length after which the path stops.
    public let maxLength: Int

    /// Default initializer.
    public init(path: PixelPath, maxLength: Int) {
        self.path = path
        self.maxLength = maxLength
    }

    // MARK: PixelPath

    /// The number of pixels that have already been returned.
    private var returnedPixels = 0

    /// Return the next pixel on the path.
    public mutating func next() -> Pixel? {
        if returnedPixels >= maxLength { return nil }

        returnedPixels += 1
        return path.next()
    }
}

// MARK: PixelPath Extension
extension PixelPath {
    /// Limit this path by a maximum length after which the path will stop.
    /// After the limited path is exhausted, you can call "limit(by:)" again to limit the path again, starting at its current state.
    public func limit(by maxLength: Int) -> PixelPath {
        LimitedPath(path: self, maxLength: maxLength)
    }
}
