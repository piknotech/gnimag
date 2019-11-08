//
//  Created by David Knothe on 06.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Geometry
import Image
import ImageAnalysisKit

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
            var failure: Failure?
            var obb: OBB?
            var result: Player?

            enum Failure {
                case eyeNotFound
                case edgeTooLarge
            }
        }

        /// Properties of the bars search.
        struct _Bars {
            var result: [Bar]?
        }
    }

    // MARK: Game Model Collection
}
