//
//  Created by David Knothe on 16.01.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// An opaque Function which is defined by a closure.
public struct FunctionWrapper: Function {
    private let block: (Value) -> Value

    /// Default initializer.
    public init(_ block: @escaping (Value) -> Value) {
        self.block = block
    }

    /// Perform the block with the given input value.
    public func at(_ x: Self.Value) -> Self.Value {
        block(x)
    }
}
