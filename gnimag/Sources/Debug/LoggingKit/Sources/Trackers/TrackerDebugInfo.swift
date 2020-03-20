//
//  Created by David Knothe on 27.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// An interface that provides shared operations for different tracker info types.
/// This is useful for grouping different TrackerDebugInfos into an array and calling shared operations on all of them.
public protocol TrackerDebugInfo {
    /// Get the data set from the data set provider and store it.
    func fetchDataSet()
}
