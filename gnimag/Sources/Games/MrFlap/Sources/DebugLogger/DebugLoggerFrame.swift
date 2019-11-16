//
//  Created by David Knothe on 06.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Geometry
import Image
import ImageAnalysisKit

/// DebugLoggerFrame stores all relevant data of a single frame, consisting of image analysis, game model collection, and tap prediction.
final class DebugLoggerFrame {
    let index: Int

    /// Default initializer.
    init(index: Int) {
        self.index = index
    }

    // MARK: Image Analysis
    var imageAnalysis = ImageAnalysis()

    /// Properties of the Image Analysis step.
    class ImageAnalysis {
        var image: Image!

        var outcome: Outcome!
        enum Outcome {
            case success
            case error
            case samePlayerPosition
        }

        var playfield = _Playfield()
        var coloring = _Coloring()
        var player = _Player()
        var bars = _Bars()

        /// Properties of the playfield search.
        struct _Playfield {
            var result: Playfield?
        }

        /// Properties of the coloring search.
        struct _Coloring {
            var result: Coloring?
            var failure: Failure?

            struct Failure {
                let pixels: [Pixel]
                let chunks: [ConnectedChunks.Chunk<Color>]
            }
        }

        /// Properties of the player search.
        struct _Player {
            var searchCenter: Pixel?
            var eyePosition: Pixel?
            var obb: OBB?
            var failure: Failure?
            var result: Player?

            enum Failure {
                case eyeNotFound
                case edgeTooLarge
            }
        }

        /// Bundles the properties of all bar searches.
        struct _Bars {
            var locations = [_BarLocation]()
            var result: [Bar]?

            var current: _BarLocation { locations.last! }

            mutating func addNewLocation() {
                locations.append(.init())
            }
        }

        /// A call to "locateBar".
        class _BarLocation {
            var startPixel: Pixel?
            var innerOBB: OBB?
            var upPosition: Pixel?
            var outerOBB: OBB?
            var failure: Failure?
            var result: Bar?

            enum Failure {
                case innerEdge
                case outerEdge
                case anglesDifferent(angle1: CGFloat, angle2: CGFloat)
                case widthsDifferent(width1: CGFloat, width2: CGFloat)
            }
        }
    }

    // MARK: Game Model Collection
}
