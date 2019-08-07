//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import ImageInput

/// Coloring describes the color scheme of the playfield.
/// It also contains game mode-specific colors used for analysis.

struct Coloring {
    /// The color of the bars and of the bird.
    /// Can change during the game.
    let theme: Color

    /// The color of the playfield. Either black or white.
    let secondary: Color

    /// The eye (or wing) color that should be searched for.
    let eyeColor: Color

    /// Default initializer.
    init(theme: Color, secondary: Color) {
        self.theme = theme
        self.secondary = secondary

        /// Determine eyeColor
        if secondary.euclideanDifference(to: .black) < secondary.euclideanDifference(to: .white) {
            // Mode: hardcore
            eyeColor = .white
        } else {
            // Mode: normal
            eyeColor = .black
        }
    }
}