//
//  Created by David Knothe on 06.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import GameKit
import Geometry
import Image
import ImageAnalysisKit
import LoggingKit

final class DebugLoggerFrame: DebugLoggerFrameProtocol {
    typealias ParameterType = DebugParameters

    var index: Int
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
                let clusters: [SimpleClustering.Cluster<Color>]
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
        var bars = _Bars()

        /// Properties of the player tracking.
        class _Player {
            var linearAngle: Double?
            var integrityCheckSuccessful = false

            var angle = SimpleTrackerDebugInfo<AngularWrapper<LinearTracker>>()
            var size = SimpleTrackerDebugInfo<ConstantTracker>()
            var height = CompositeTrackerDebugInfo<ParabolaTracker>()

            /// Do necessary preparations before logging.
            func prepareForLogging() {
                height.fetchFunctionInfos()
                for tracker in [angle, size, height] as [TrackerDebugInfo] {
                    tracker.fetchDataSet()
                }
            }
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

            var angle = SimpleTrackerDebugInfo<AngularWrapper<LinearTracker>>()
            var width = SimpleTrackerDebugInfo<ConstantTracker>()
            var appearingHoleSize = SimpleTrackerDebugInfo<LinearTracker>()
            var holeSize = SimpleTrackerDebugInfo<ConstantTracker>()
            var yCenter = CompositeTrackerDebugInfo<LinearTracker>()

            /// Do necessary preparations before logging.
            func prepareForLogging() {
                yCenter.fetchFunctionInfos()
                for tracker in [yCenter, angle, width, appearingHoleSize, holeSize] as [TrackerDebugInfo] {
                    tracker.fetchDataSet()
                }
            }
        }
    }
}
