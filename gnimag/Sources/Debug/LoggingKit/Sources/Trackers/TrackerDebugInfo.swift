//
//  Created by David Knothe on 27.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// An interface that provides shared operations for different tracker info types.
public protocol TrackerDebugInfo {
    /// Get the data set from the data set provider and store it.
    func fetchDataSet()

    /// Get function infos from the data set provider and store it.
    func fetchFunctionInfos()
}
