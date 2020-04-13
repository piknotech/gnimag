//
//  Created by David Knothe on 13.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import GameKit

extension MrFlapGameSimulation {
    /// The simulated player object.
    struct Player {
        var size: CGFloat = 10

        /// The current position (angle and height) of the player which depends on the current time.
        fileprivate var currentTime: Double = 0

        var height: CGFloat { CGFloat(currentJump?.parabola(currentTime) ?? Double(startHeight)) }
        private let startHeight: CGFloat!

        var angle: CGFloat { CGFloat(angleFunction(currentTime)) }
        private let angleFunction = LinearFunction(slope: -1, intercept: .pi / 2)

        /// The current jump.
        private var currentJump: Jump!

        /// Default initializer.
        init(height: CGFloat) {
            startHeight = height
        }

        /// Begin a jump at the current time.
        mutating func jump() {
            currentJump = Jump(player: self)
        }

        /// Update the player by updating its current time and therefore its position.
        mutating func update(currentTime: Double) {
            self.currentTime = currentTime
        }
    }

    /// A Jump describes a player's jump.
    private struct Jump {
        let parabola: Parabola

        private let jumpVelocity: Double = 300
        private let gravity: Double = 1200 // -> Jump duration = 0.5s

        /// Create a jump starting at the player's current position, such that `parabola(startTime) = player.height`.
        init(player: Player) {
            let time = player.currentTime

            let a = -0.5 * gravity // f''(time) = -gravity
            let b = jumpVelocity + gravity * time // f'(time) = jumpVelocity
            let c = Double(player.height) - a * time * time - b * time // f(time) = player.height
            self.parabola = Parabola(a: a, b: b, c: c)
        }
    }
}
