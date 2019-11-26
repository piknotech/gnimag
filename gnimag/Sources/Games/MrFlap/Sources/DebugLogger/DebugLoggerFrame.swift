//
//  Created by David Knothe on 06.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import GameKit
import Geometry
import Image
import ImageAnalysisKit

/// DebugLoggerFrame stores all relevant data of a single frame, consisting of image analysis, game model collection, and tap prediction.
final class DebugLoggerFrame {
    let index: Int // Starts at 1.
    var time: Double?
    
    /// Default initializer.
    init(index: Int) {
        self.index = index
    }

    // MARK: Hints
    var hints = Hints()

    /// Properties of the image analysis hints calculation.
    class Hints {
        var usingInitialHints = false
        var hints: AnalysisHints?
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
        class _Playfield {
            var result: Playfield?
        }

        /// Properties of the coloring search.
        class _Coloring {
            var result: Coloring?
            var failure: Failure?

            struct Failure {
                let pixels: [Pixel]
                let chunks: [ConnectedChunks.Chunk<Color>]
            }
        }

        /// Properties of the player search.
        class _Player {
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
        class _Bars {
            var locations = [_BarLocation]()
            var result: [Bar]?

            var current: _BarLocation { locations.last! }

            func nextBarLocation() {
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
    let gameModelCollection = GameModelCollection()

    /// Properties of the Game Model Collection step.
    class GameModelCollection {
        var wasPerformed = false

        var player = _Player()
        var barMatchings = _BarMatchings()
        var bars = _Bars()

        /// Properties of the player tracking.
        class _Player {
            var linearAngle: Double?
            var integrityCheckSuccessful = false

            var angle = SimpleTrackerDebugInfo()
            var size = SimpleTrackerDebugInfo()
            var height = CompositeTrackerDebugInfo<PolyTracker>()

            /// Do necessary preparations before logging.
            func prepareForLogging() {
                angle.fetchDataSet(); size.fetchDataSet()
                height.fetchDataSet()
            }
        }

        /// Bundles the properties of the bar matching algorithm.
        class _BarMatchings {

        }

        /// Bundles the properties of all bar trackings.
        class _Bars {
            var all = [_Bar]()
            var current: _Bar { all.last! }

            func nextBar() {
                all.append(.init())
            }
        }

        /// A single bar tracker.
        class _Bar {
            var state: BarCourse.State?
            var stateSwitch = false // True when a state switch was detected in this exact frame
            var integrityCheckSuccessful = false

            var angle = SimpleTrackerDebugInfo()
            var width = SimpleTrackerDebugInfo()
            var appearingHoleSize = SimpleTrackerDebugInfo()
            var holeSize = SimpleTrackerDebugInfo()
            var yCenter = CompositeTrackerDebugInfo<LinearTracker>()

            /// Do necessary preparations before logging.
            func prepareForLogging() {
                yCenter.fetchDataSet() // TODO: superclass/protocol
                for var info in [angle, width, appearingHoleSize, holeSize] {
                    info.fetchDataSet()
                }
            }
        }
    }
}
