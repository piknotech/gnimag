//
//  Created by David Knothe on 20.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Image
import Tapping

public class MrFlap {
    private let imageProvider: ImageProvider
    private let tapper: Tapper

    /// The image analyzer.
    private let imageAnalyzer = ImageAnalyzer()

    /// Default initializer.
    public init(imageProvider: ImageProvider, tapper: Tapper) {
        self.imageProvider = imageProvider
        self.tapper = tapper
    }

    /// Begin receiving images and play the game.
    public func play() {
        imageProvider.newImage.subscribe { value in
            let (image, _) = value
            let _ = self.imageAnalyzer.analyze(image: image, hints: AnalysisHints())
        }
    }
}
