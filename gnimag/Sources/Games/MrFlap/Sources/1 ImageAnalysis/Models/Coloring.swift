//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Image
import ImageAnalysisKit

/// Coloring describes the color scheme of the playfield.
/// It also contains game mode-specific colors used for analysis.
struct Coloring {
    /// The color of the bars and of the bird.
    /// Can change during the game.
    let theme: Color

    /// The color of the playfield. Either black or white.
    let secondary: Color

    /// The eye or wing color that identifies the player. It is unique and does not appear anywhere else on the playfield.
    let eye: ColorMatch

    /// A reliable way to determine whether the player has crashed. When the theme color matches this crash color, the player has crashed.
    let crashColor: ColorMatch

    /// A color that is safe on draw with both on foreground and background.
    let safeLoggingColor: Color

    /// The game mode which corresponds to the coloring.
    let mode: GameMode

    /// Default initializer.
    /// Fails when there is no game mode matching the coloring.
    init?(theme: Color, secondary: Color) {
        self.theme = theme
        self.secondary = secondary

        guard let mode = GameMode.from(secondaryColor: secondary) else { return nil }
        self.mode = mode

        /// Determine eyeColor, safeLoggingColor and crashColor
        switch mode {
        case .normal:
            eye = .color(.black, tolerance: 0.25)
            crashColor = .color(Color(0.25, 0.25, 0.25), tolerance: 0.1)
            safeLoggingColor = .red

        case .hard:
            eye = .color(.white, tolerance: 0.05)
            crashColor = .color(.white, tolerance: 0.1)
            safeLoggingColor = Color(0.5, 0.5, 1) // light blue
        }
    }
}

enum GameMode {
    case normal
    case hard

    /// Read the game mode from the given coloring, if possible.
    static fileprivate func from(secondaryColor: Color) -> GameMode? {
        if secondaryColor.distance(to: .white) < 0.1 { return .normal }
        if secondaryColor.distance(to: .black) < 0.1 { return .hard }
        return nil
    }
}
