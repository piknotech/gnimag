//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import ImageInput

/// ColorMatchSequence is a sequential collection of ColorMatches.
public struct ColorMatchSequence {
    public let sequence: [ColorMatch]

    /// Initialize the sequence with an array.
    /// The array must not be empty.
    public init(_ sequence: [ColorMatch]) {
        self.sequence = sequence
    }

    /// Initialize the sequence with variadic arguments.
    /// The arguments must not be empty.
    public init(_ sequence: ColorMatch...) {
        self.sequence = sequence
    }

    /// Initialize with a tolerance and a sequence of colors or anti-colors (!blue).
    public init(tolerance: Double, colors: [NeedsToleranceValue]) {
        self.sequence = colors.map { $0.withTolerance(tolerance) }
    }
}

extension Image {
    /// Continue a path inside the image until the whole ColorMatchSequence was matched.
    /// When the last match of the sequence has been hit, return the last pixel and the current pixel.
    public func follow(path: inout PixelPath, untilFulfillingSequence sequence: ColorMatchSequence) -> SequenceFulfillmentResult {
        var currentSequenceIndexToMatch = 0
        var lastPixel: Pixel?

        while let pixel = path.next() {
            // Check if pixel matches the current match
            let currentMatch = sequence.sequence[currentSequenceIndexToMatch]
            if currentMatch.matches(color(at: pixel)) {
                currentSequenceIndexToMatch += 1
            }

            // Check if sequence is fulfilled
            if currentSequenceIndexToMatch == sequence.sequence.count {
                return .fulfilled(
                    previousPixel: lastPixel,
                    fulfilledPixel: pixel
                )
            }

            lastPixel = pixel
        }

        // Path finished, sequence not fulfilled
        return .notFulfilled(
            lastPixelOfPath: lastPixel,
            highestFulfilledSequenceIndex: currentSequenceIndexToMatch - 1
        )
    }

    public enum SequenceFulfillmentResult {
        /// The sequence has been fulfilled; return the previous pixel and the pixel that triggered the fulfillment.
        case fulfilled(previousPixel: Pixel?, fulfilledPixel: Pixel)

        /// The sequence has not been fulfilled; return the last pixel of the path and the highest sequence index that has been fulfilled (this may be -1 if nothing has been matched).
        case notFulfilled(lastPixelOfPath: Pixel?, highestFulfilledSequenceIndex: Int)
    }
}
