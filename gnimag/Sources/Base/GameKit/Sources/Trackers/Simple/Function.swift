//
//  Created by David Knothe on 07.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// Describes a function whose domain and codomain are both the real numbers (represented by `Double`).
public protocol Function {
    typealias Value = Double
    
    /// Calculate the value at a given point.
    func at(_ x: Value) -> Value
}
