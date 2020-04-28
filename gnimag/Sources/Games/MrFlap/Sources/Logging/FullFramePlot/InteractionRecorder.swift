//
//  Created by David Knothe on 19.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common

/// InteractionRecorder stores all PlayerBarInteractions in the order they appear.
/// Once an interaction has been (successfully) completed, it can be stored via InteractionRecorder.
/// Then, when drawing a FullFramePlot, the passed interactions can be retrieved.
final class InteractionRecorder {
    /// All interactions that have been passed.
    private(set) var passedInteractions: FixedSizeFIFO<PlayerBarInteraction>

    /// The most recent interaction. Once an incoming interaction does not match this interaction, this interaction will be marked as passed.
    private var mostRecentInteraction: PlayerBarInteraction?

    /// Triggered each time an interaction is fully completed and a new one is detected.
    /// The parameter is the completed interaction.
    let interactionCompleted = Event<PlayerBarInteraction>()

    /// Default initializer.
    init(maximumStoredInteractions: Int) {
        passedInteractions = FixedSizeFIFO<PlayerBarInteraction>(capacity: maximumStoredInteractions)
    }

    /// Call each frame with the upcoming interaction.
    /// If this interaction is new, i.e. does not match the previous one, the previous interaction will be marked as completed.
    func add(interaction: PlayerBarInteraction) {
        if let mostRecent = mostRecentInteraction, isNew(interaction: interaction) {
            passedInteractions.append(mostRecent)
            interactionCompleted.trigger(with: mostRecent)
        }

        mostRecentInteraction = interaction

        // Remove most recent interaction when bar disappears
        interaction.barTracker.disappearedOrOrphaned.unsubscribe(self)
        interaction.barTracker.disappearedOrOrphaned += self • {
            if self.mostRecentInteraction?.barTracker == interaction.barTracker {
                self.mostRecentInteraction = nil
            }
        }
    }

    /// Return all interactions whose reference time is smaller than a given time.
    /// Also, discard (early) interactions which do not intersect a given time range.
    func interactions(before: Double, intersectingRange range: SimpleRange<Double>) -> [PlayerBarInteraction] {
        passedInteractions.elements.filter {
            $0.currentTime < before &&
            !$0.fullInteractionRange.shifted(by: $0.currentTime).intersection(with: range).isEmpty
        }
    }

    /// Determine whether an interaction is an actual new bar or if it just matches the last interaction.
    private func isNew(interaction: PlayerBarInteraction) -> Bool {
        guard let mostRecent = mostRecentInteraction else { return true }

        let tolerance = 0.05
        return interaction.timeUntilLeaving > mostRecent.timeUntilLeaving + tolerance
    }
}
