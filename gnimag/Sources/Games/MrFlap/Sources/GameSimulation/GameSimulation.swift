//
//  Created by David Knothe on 13.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Geometry
import Image
import Tapping
import TestingTools

/// Use MrFlapGameSimulation to simulate a full MrFlap game.
public final class MrFlapGameSimulation: ImageProvider, SomewhereTapper {
    private let screenSize = CGSize(width: 400, height: 400)

    private lazy var playfield = Playfield(
        center: CGPoint(x: screenSize.width / 2, y: screenSize.height / 2),
        innerRadius: 40,
        fullRadius: 180
    )

    private lazy var player = Player(
        height: CGFloat(playfield.innerRadius + 0.5 * playfield.freeSpace)
    )

    // Timing properties.
    private var elapsedTime: Double = 0 // Time (0-based) since initialization of the simulation.
    private var timeOfFirstTap: Double! // Time (0-based) since `tap` was called to start the game.
    private var isRunning: Bool { timeOfFirstTap != nil }

    private var startSystemTime: Double! // Absolute system time of initialization of the simulation.
    private var timer: Timer!

    /// Default initializer.
    /// Immediately begin providing images.
    public init(fps: Double) {
        startSystemTime = CACurrentMediaTime()
        timer = Timer.scheduledTimer(withTimeInterval: 1 / fps, repeats: true) { _ in
            self.gameUpdate()
        }
    }

    /// Tap on the screen to either jump or start the game.
    public func tap() {
        if !isRunning {
            timeOfFirstTap = elapsedTime
        }

        player.jump()
    }

    /// Called each frame to update game elements and provide the current image.
    @objc private func gameUpdate() {
        elapsedTime = CACurrentMediaTime() - startSystemTime

        if isRunning {
            player.update(currentTime: elapsedTime - timeOfFirstTap)
        }

        newFrame.trigger(with: (NativeImage(currentImage), elapsedTime))
    }

    // MARK: ImageProvider

    public lazy var timeProvider = TimeProvider { self.elapsedTime }
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

        return canvas.CGImage
    }
}
