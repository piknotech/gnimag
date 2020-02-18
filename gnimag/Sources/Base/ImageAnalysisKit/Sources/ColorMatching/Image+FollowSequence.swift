//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Image

extension Image {
    /// Continue a path inside the image until the whole ColorMatchSequence was matched.
    /// When the last match of the sequence has been hit, return the last pixel and the current pixel.
    public final func follow(path: PixelPath, untilFulfillingSequence sequence: ColorMatchSequence) -> SequenceFulfillmentResult {
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
        /// `previousPixel` can only be nil if the ColorMatchSequence only consists of one color match.
        case fulfilled(previousPixel: Pixel?, fulfilledPixel: Pixel)

        /// The sequence has not been fulfilled; return the last pixel of the path and the highest sequence index that has been fulfilled.
        /// If no color match has been fulfilled, `highestFulfilledSequenceIndex` is -1.
        case notFulfilled(lastPixelOfPath: Pixel?, highestFulfilledSequenceIndex: Int)

        /// Return the pixel which fulfilled the sequence, or nil if the sequence was not fulfilled.
        public var fulfilledPixel: Pixel? {
            guard case let .fulfilled(_, fulfilledPixel: pixel) = self else { return nil }
            return pixel
        }

        /// Return the pixel before the one which fulfilled the sequence, or nil if the sequence was not fulfilled or was fulfilled immediately (by the first pixel).
        public var beforeFulfillment: Pixel? {
            guard case let .fulfilled(previousPixel: pixel, _) = self else { return nil }
            return pixel // Can be nil
        }
    }
}
