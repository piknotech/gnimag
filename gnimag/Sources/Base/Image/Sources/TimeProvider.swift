//
//  Created by David Knothe on 18.02.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

public class TimeProvider {
    public typealias Time = Double

    /// The time providing primitive.
    private let block: () -> Time

    /// All times are shifted by this time value so the first frame's time starts at 0.
    private lazy var startTime: Time = block()

    /// Default initializer.
    public init(_ block: @escaping () -> Time) {
        self.block = block
    }

    /// Get the current time.
    /// Time starts at approximately zero, i.e. the first call to `time` will return approximately 0.
    public var currentTime: Time {
        -startTime + block()
    }
}
