//
//  Created by David Knothe on 29.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Dispatch

/// TapPredictionQueue provides a queue on which a custom tap prediction logic callback is performed in a desired time interval.
public final class TapPredictionQueue {
    /// Information about how the tap prediction logic is performed.
    private let queue: DispatchQueue
    private let interval: Double
    private let predictionCallback: () -> Void

    /// The dispatch timer, which is nil if the queue has not been `start`ed (or `stop`ped).
    private var timer: DispatchSourceTimer?

    /// Default initializer.
    public init(interval: Double, predictionCallback: @escaping () -> Void) {
        queue = DispatchQueue.global(qos: .userInitiated)
        self.interval = interval
        self.predictionCallback = predictionCallback
    }

    /// Begin the timed callback loop on the queue.
    public func start() {
        let ms = DispatchTimeInterval.milliseconds(Int(interval * 1000))
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer!.schedule(deadline: .now() + ms, repeating: ms)
        timer!.setEventHandler(handler: predictionCallback)
        timer!.resume()
    }

    /// Stop the timed callback loop.
    public func stop() {
        timer?.cancel()
        timer = nil
    }
}
