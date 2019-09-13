//
//  Created by David Knothe on 20.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Geometry
import Image
import Tapping

public class MrFlap {
    private let imageProvider: ImageProvider
    private let tapper: Tapper

    /// The image analyzer.
    private let imageAnalyzer = ImageAnalyzer()
    private var nextHints: AnalysisHints!

    /// Default initializer.
    public init(imageProvider: ImageProvider, tapper: Tapper) {
        self.imageProvider = imageProvider
        self.tapper = tapper
    }

    /// Begin receiving images and play the game.
    public func play() {
        imageProvider.newImage.subscribe { value in
            let (image, _) = value
            self.analyze(image: image)
        }
    }

    private func analyze(image: Image) {
        nextHints = nextHints ?? initialHints(for: image)
        let analysis = self.imageAnalyzer.analyze(image: image, hints: nextHints)

        switch analysis {
        case let .success(result):
            // Update hints
            nextHints = AnalysisHints(expectedPlayerPosition: result.player.coords)

        case .failure:
            ()
        }
    }

    /// Use approximated default values to create hints for the first image.
    private func initialHints(for image: Image) -> AnalysisHints {
        AnalysisHints(
            expectedPlayerPosition: PolarCoordinates(angle: .pi / 2, height: 0.2 * CGFloat(image.height))
        )
    }
}
