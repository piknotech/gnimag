//
//  Created by David Knothe on 29.11.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// A DebugFrame stores all relevant data of a single frame.
/// When this data is erroneous / otherwise relevant, it will be logged asynchronously.
public protocol DebugFrameProtocol {
    associatedtype ParameterType: DebugParameterType

    /// The index of the frame, starting at 1.
    var index: Int { get }
    init(index: Int)

    /// State if the frame should be logged or not.
    func isValidForLogging(with parameters: ParameterType) -> Bool

    /// Do synchronous preparations that are required for later, asynchronous, logging.
    /// Only called when `isValidForLogging(with:)` returned `true`.
    func prepareSynchronously(with parameters: ParameterType)

    /// Log the frame. This method is called asynchronously, an undefined time after the frame was actually live.
    /// Only called when `isValidForLogging(with:)` returned `true`.
    func log(with parameters: ParameterType)
}
