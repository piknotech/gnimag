//
//  Created by David Knothe on 19.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// InteractionRecorder stores all PlayerBarInteractions in the order they appear.
/// Once an interaction has been (successfully) completed, it can be stored via InteractionRecorder.
/// Then, when drawing a FullFramePlot, the passed interactions can be retrieved.
final class InteractionRecorder {
    /// All interactions that have been passed.
    private(set) var passedInteractions = [PlayerBarInteraction]()

    /// The most recent interaction. Once an incoming interaction does not match this interaction, this interaction will be marked as passed.
    private var mostRecentInteraction: PlayerBarInteraction?

    /// Call each frame with the upcoming interaction.
    /// If this interaction is new, i.e. does not match the previous one, the previous interaction will be marked as completed.
    func add(interaction: PlayerBarInteraction) {
        if let mostRecent = mostRecentInteraction, isNew(interaction: interaction) {
            passedInteractions.append(mostRecent)
        }

        mostRecentInteraction = interaction
    }

    /// Determine whether an interaction is an actual new bar or if it just matches the last interaction.
    private func isNew(interaction: PlayerBarInteraction) -> Bool {
        guard let mostRecent = mostRecentInteraction else { return true }
        if interaction.barTracker != mostRecent.barTracker { return true }

        let errorTolerance = 0.1
        return interaction.timeUntilHittingCenter > mostRecent.timeUntilHittingCenter + errorTolerance
    }
}
