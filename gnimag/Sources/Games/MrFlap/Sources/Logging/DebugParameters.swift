//
//  Created by David Knothe on 14.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import LoggingKit

/// DebugParameters allow the user of MrFlap to configure the location and the severity of the debug logging.
public struct DebugParameters: DebugParameterType {
    /// The path to the directory in which the logging is performed.
    public let location: String

    /// Occasions on which frames are logged.
    public let occasions: Occasions
    public struct Occasions: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let imageAnalysisErrors = Occasions(rawValue: 1 << 0)
        public static let barLocationErrors = Occasions(rawValue: 1 << 1)
        public static let integrityErrors = Occasions(rawValue: 1 << 2)
        public static let errors: Occasions = [.imageAnalysisErrors, .barLocationErrors, .integrityErrors]
        public static let interestingTapPrediction = Occasions(rawValue: 1 << 3)
    }

    /// The content that is logged.
    public let content: LoggingContent
    public struct LoggingContent: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let text = LoggingContent(rawValue: 1 << 0)
        public static let imageAnalysis = LoggingContent(rawValue: 1 << 1)
        public static let gameModelCollection = LoggingContent(rawValue: 1 << 2)
        public static let tapPrediction = LoggingContent(rawValue: 1 << 3)
        public static let all: LoggingContent = [.text, .imageAnalysis, .gameModelCollection, .tapPrediction]
    }

    /// When set, every `controlFramerate` frames the current frame is logged, independent of whether it matches one of the occasions.
    public let controlFramerate: Int?

    /// Default initializer.
    public init(location: String, occasions: Occasions, logEvery controlFramerate: Int? = nil, content: LoggingContent = .all) {
        self.location = location
        self.occasions = occasions
        self.controlFramerate = controlFramerate
        self.content = content
    }

    /// Shorthand for no logging.
    public static let none = DebugParameters(location: "", occasions: [])

    internal var isNone: Bool {
        location.isEmpty
    }
}
