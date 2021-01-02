//
//  Created by David Knothe on 02.04.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// GameColor describes a color on the field.
/// Thereby, two GameColor instances are equal if they are represented by the same letter.
struct GameColor {
    /// All possible letters that you can use when creating a GameColor instance.
    /// You could use different letters, but these are the only ones supported by the solver scripts.
    static let allLetters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P"]

    /// A letter that is used to uniquely represent this GameColor.
    let letter: String
}

extension GameColor: Equatable {
    static func ==(lhs: GameColor, rhs: GameColor) -> Bool {
        lhs.letter == rhs.letter
    }
}

extension GameColor: Hashable {
    func hash(into hasher: inout Hasher) {
        letter.hash(into: &hasher)
    }
}
