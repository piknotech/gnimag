//
//  Created by David Knothe on 23.09.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Dispatch

class TerminationHandler {
    private var sources: [DispatchSourceSignal]!

    /// Setup signal processing
    private init() {
        sources = [SIGINT, SIGTERM, SIGKILL].map { SIGNAL in
            signal(SIGNAL, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: SIGNAL, queue: .main)
            source.setEventHandler { self.onTerminate.trigger() }
            source.resume()
            return source
        }

        atexit { TerminationHandler.shared.onTerminate.trigger() }
    }

    static let shared = TerminationHandler()

    /// The event which is triggered on SIGINT and SIGTERM.
    let onTerminate = Event<Void>()
}
