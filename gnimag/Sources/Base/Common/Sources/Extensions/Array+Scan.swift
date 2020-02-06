//
//  Created by David Knothe on 25.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

extension Array {
    /// Scan the array from front to back, performing an operation for each element with the current partial result, and return all partial results at the end.
    /// The size of the result is 1 larger than the size of `self`.
    @_transparent
    public func scan<T>(initial: T, _ f: (T, Element) -> T) -> [T] {
        return self.reduce([initial], { (listSoFar: [T], next: Element) -> [T] in
            let lastElement = listSoFar.last!
            return listSoFar + [f(lastElement, next)]
        })
    }
}
