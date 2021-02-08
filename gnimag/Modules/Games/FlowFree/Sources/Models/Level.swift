//
//  Created by David Knothe on 29.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// Full description of an (unsolved) Flow Free level.
struct Level {
    /// The level consists of targets, for each of which a connection has to be found.
    struct Target {
        let color: GameColor
        let point1: Position
        let point2: Position
    }

    /// All targets, indexed by their color.
    let targets: [GameColor: Target]

    /// The number of boxes per row or per column.
    let boardSize: Int
}

extension Level: Equatable {
    /// Compare two levels for semantic equality.
    /// Two levels are equal if they represent the same structure, irrespective of the exact GameColors.
    static func ==(lhs: Self, rhs: Self) -> Bool {
        if lhs.boardSize != rhs.boardSize { return false }
        if lhs.targets.count != rhs.targets.count { return false }

        // Match each lhs-color to an rhs-color
        for target1 in lhs.targets.values {
            let hasMatch = rhs.targets.values.any { target2 in
                targetsAreSimilar(target1, target2)
            }
            if !hasMatch { return false }
        }

        return true
    }

    /// Decide whether two Targets have the same start and end positions, irrespective of their color.
    private static func targetsAreSimilar(_ target1: Level.Target, _ target2: Level.Target) -> Bool {
        target1.point1 == target2.point1 && target1.point2 == target2.point2 ||
        target1.point1 == target2.point2 && target1.point2 == target2.point1
    }
}
