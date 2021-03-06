//
//  Created by David Knothe on 13.04.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import Geometry
import Image
import QuartzCore
import Tapping
import TestingTools

/// Use MrFlapGameSimulation to simulate a full MrFlap game.
public final class MrFlapGameSimulation: ImageProvider, SomewhereTapper {
    let screenSize = CGSize(width: 400, height: 400)

    private lazy var playfield = Playfield(
        center: CGPoint(x: screenSize.width / 2, y: screenSize.height / 2),
        innerRadius: 40,
        fullRadius: 180
    )

    private lazy var player = Player(
        height: CGFloat(playfield.innerRadius + 0.4 * playfield.freeSpace)
    )

    private lazy var bars = [0, 1, 2].map { i -> Bar in
        let angle = (0.6 + 2/3 * Double(i)) * .pi
        return Bar(angle: angle, angularSpeed: 0.4, yCenterPeriodDuration: 2, playfield: playfield)
    }

    /// Time (0-based) since initialization of the simulation.
    private var elapsedTime: Double { timeProvider.currentTime }

    private var timeOfFirstTap: Double! // Time (0-based) since `tap` was called to start the game.
    private var isRunning: Bool { timeOfFirstTap != nil }

    private let fps: Double
    private var timer: Timer!

    /// Default initializer.
    /// Immediately begin providing images.
    public init(fps: Double) {
        self.fps = fps
        self.timer = Timer.scheduledTimer(withTimeInterval: 1 / fps, repeats: true) { _ in
            self.gameUpdate()
        }
    }

    /// Tap on the screen to either jump or start the game.
    public func tap() {
        Timing.shared.perform(after: 0.25) { // Artificial delay
            if !self.isRunning {
                self.timeOfFirstTap = self.elapsedTime
            }

            self.player.jump(currentRealTime: self.elapsedTime - self.timeOfFirstTap, fps: self.fps)
        }
    }

    /// Called each frame to update game elements and provide the current image.
    @objc private func gameUpdate() {
        if isRunning {
            player.update(currentTime: elapsedTime - timeOfFirstTap)
            for i in 0 ..< bars.count {
                bars[i].update(currentTime: elapsedTime - timeOfFirstTap)
            }
        }

        let t = elapsedTime
        newFrame.trigger(with: (NativeImage(currentImage), t))
    }

    // MARK: ImageProvider

    public let timeProvider = TimeProvider(CACurrentMediaTime)
    public let newFrame = Event<Frame>()

    /// Draw the current game state.
    private var currentImage: CGImage {
        let canvas = BitmapCanvas(width: Int(screenSize.width), height: Int(screenSize.height))
        canvas.background(.blue)

        // Draw playfield
        canvas.fill(Circle(center: playfield.center, radius: CGFloat(playfield.fullRadius)), with: .white)
        canvas.fill(Circle(center: playfield.center, radius: CGFloat(playfield.innerRadius)), with: .blue)

        // Draw player
        let playerCenter = PolarCoordinates.position(atAngle: player.angle, height: player.height, respectiveTo: playfield.center)
        let playerOBB = OBB(center: playerCenter, width: player.size, height: player.size, rotation: player.angle)
        canvas.fill(playerOBB, with: .blue)

        // Draw player eye
        canvas.fill(playerCenter.nearestPixel, with: .black, width: 3)

        // Draw bars
        if isRunning {
            for bar in bars {
                for obb in bar.obbs(forDrawingIn: playfield) {
                    canvas.fill(obb, with: .blue)
                }
            }
        }

        return canvas.CGImage
    }
}
