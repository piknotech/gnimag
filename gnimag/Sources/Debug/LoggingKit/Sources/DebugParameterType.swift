//
//  Created by David Knothe on 29.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// Minimum requirements for debug parameters.
public protocol DebugParameterType {
    /// The location of the directory on disk which will be used for logging.
    var location: String { get }
}
