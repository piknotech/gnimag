//
//  Created by David Knothe on 15.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation

/// TopPrismColor describes the color that is on top of an idle or currently rotating prism.
/// The game doesn't care whether the prism is rotating towards color C or is idle with top color C when a dot hits the critical position.
/// If the prism is rotating wildly (i.e. clockwise), the top color is unsure until the prism has become idle.
enum TopPrismColor: Equatable {
    /// Prism is either idle or rotating counterclockwise towards this top color.
    case color(DotColor)

    /// Happens when double tapping quickly: the prism rotates clockwise. Also called "rotating wildy".
    case unsure
}

/// PrismStateTracker keeps track of the prism's rotation and always yields the current `TopPrismColor`.
/// Others can either retrieve this color or query whether it has changed during the last `update` cycle.
final class PrismStateTracker {
    /// The current top color, or `unsure` during a wild rotation.
    @Observable(initialChange: false)
    var topColor: TopPrismColor = .unsure

    /// The latest changes to `topColor`. Accessing `latestColorChanges` will clear its contents.
    var mostRecentChanges: [Observable<TopPrismColor>.Change] { _topColor.latestChanges }
    var mostRecentChange: TopPrismColor? { _topColor.mostRecentChange }

    /// Properties of a transition from `unsure` to an idle `color`.
    private var wildToIdleTransition: (candidate: DotColor, consecutiveFrames: Int)?

    private var lastAngle: Angle?

    /// Update the tracker with the new prism angle.
    func update(with angle: Angle) {
        defer { lastAngle = angle }

        // First time
        guard let lastAngle = lastAngle else {
            let color = Prism.topColor(angle: angle) ??
                Prism.nextTopColorRotatingCounterclockwise(currentAngle: angle)

            topColor = .color(color)
            return
        }

        // If angle hasn't changed and rotation is not wild: nothing to do
        if lastAngle.distance(to: angle) < 0.05, topColor != .unsure {
            return
        }

        // On idle angle during `unsure`, try transitioning back to `idle`
        if topColor == .unsure, let color = Prism.topColor(angle: angle) {
            if let (candidate, counter) = wildToIdleTransition, candidate == color {
                if counter + 1 >= 2 { // Transition successful
                    topColor = .color(candidate)
                } else {
                    wildToIdleTransition = (candidate, counter + 1)
                }
            } else {
                wildToIdleTransition = (color, 1)
            }
        }
        else if topColor == .unsure { // Remain in `unsure` mode
            wildToIdleTransition = nil
            return
        }

        else { // topColor == .color(...)
            // Determine rotation direction from oldAngle -> newAngle
            let ccw = lastAngle.directedDistance(to: angle, direction: 1) < .pi

            if ccw { // Normal, counterclockwise rotation
                let color = Prism.topColor(angle: angle) ??
                    Prism.nextTopColorRotatingCounterclockwise(currentAngle: angle)
                topColor = .color(color)
            } else { // Rotation is clockwise, go to `unsure`
                topColor = .unsure
                wildToIdleTransition = nil
            }
        }
    }
}

// MARK: - Color/Angle Conversion
private struct Prism {
    /// Return the DotColor corresponding to the top color of a prism with `angle` rotation.
    /// Thereby, 0° corresponds to orange, 120° to violet and 240° to skyBlue.
    /// If the angle doesn't correspond to the idle position of one of the three colors (within +- `tolerance`), return nil.
    static func topColor(angle: Angle, tolerance: Double = 0.05) -> DotColor? {
        let rotations = angle.value / (2 * .pi / 3)
        guard abs(rotations - round(rotations)) < tolerance else { return nil }

        let fullRotations = Int(round(rotations))
        return iterate(.orange, \.next, fullRotations)
    }

    /// Return the DotColor that is the next top color on a prism when it is currently rotating counterclockwise (i.e. with increasing angle).
    /// This splits the prism into three angular segments: [0, 120) for violet, [120, 240) for skyBlue and [240, 0) for orange.
    static func nextTopColorRotatingCounterclockwise(currentAngle: Angle) -> DotColor {
        let rotations = currentAngle.value / (2 * .pi / 3)
        let fullRotations = Int(floor(rotations))
        return iterate(.orange, \.next, fullRotations + 1)
    }

    /// Iterate `x` under `f` `n` times
    private static func iterate<A>(_ x: A, _ f: (A) -> A, _ n: Int) -> A {
        n <= 0 ? x : iterate(f(x), f, n-1)
    }
}

// MARK: - Observable
/// Observable tracks all changes that are performed to the property.
/// The changes are collected and can be accessed via `changes`. Accessing `changes` clears the stored changes.
@propertyWrapper class Observable<A: Equatable> {
    /// Contains all changes since the **last read access** to `latestChanges`.
    /// Accessing `latestChanges` will clear its contents.
    var latestChanges: [Change] {
        let result = _latestChanges
        _latestChanges.removeAll()
        return result
    }
    private var _latestChanges =  [Change]()
    struct Change {
        let from: A
        let to: A
    }

    /// The value of the most recent change, if there is one, else nil.
    /// Reading this will clear `latestChanges`.
    var mostRecentChange: A? { latestChanges.last?.to }

    /// Default initializer.
    init(wrappedValue value: A, initialChange: Bool) {
        wrappedValue = value
        _latestChanges = initialChange ? [Change(from: value, to: value)] : []
    }

    /// A wrapper around `value`.
    var wrappedValue: A {
        willSet {
            if wrappedValue != newValue {
                _latestChanges.append(Change(from: wrappedValue, to: newValue))
            }
        }
    }
}
