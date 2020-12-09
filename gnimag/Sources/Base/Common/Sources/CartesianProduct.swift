//
//  Created by David Knothe on 17.10.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//
// Taken from http://www.figure.ink/blog/2017/7/30/lazy-permutations-in-swift

/// A much more performant version of product(a, b).map(block).
@_transparent
public func cartesianMap<T, U, V>(_ array1: [T], _ array2: [U], block: (T, U) -> V) -> [V] {
    var result = [V]()
    result.reserveCapacity(array2.count * array2.count)

    // Use plain loops for a great performance increase in comparsion to ×/map
    for elem1 in array1 {
        for elem2 in array2 {
            result.append(block(elem1, elem2))
        }
    }

    return result
}

// MARK: Cartesian Product

infix operator ×

/// Calculate the cartesian product of two collections (lazily).
public func ×<X, Y>(_ xs: X, _ ys: Y) -> CartesianProductSequence<X, Y> where X: Sequence, Y: Collection {
    product(xs, ys)
}

/// Calculate the cartesian product of two collections (lazily).
public func product<X, Y>(_ xs: X, _ ys: Y) -> CartesianProductSequence<X, Y> where X: Sequence, Y: Collection {
    CartesianProductSequence(xs: xs, ys: ys)
}

public struct CartesianProductSequence<X, Y>: Sequence where X: Sequence, Y: Collection {
    public typealias Iterator = CartesianProductIterator<X.Iterator, Y>

    private let xs: X
    private let ys: Y

    public init(xs: X, ys: Y) {
        self.xs = xs
        self.ys = ys
    }

    public func makeIterator() -> Iterator {
        Iterator(xs: xs.makeIterator(), ys: ys)
    }
}

public struct CartesianProductIterator<X, Y>: IteratorProtocol where X: IteratorProtocol, Y: Collection {
    public typealias Element = (X.Element, Y.Element)

    private var xs: X
    private let ys: Y

    private var x: X.Element?
    private var yIt: Y.Iterator

    public init(xs: X, ys: Y) {
        self.xs = xs
        self.ys = ys

        x = self.xs.next()
        yIt = self.ys.makeIterator()
    }

    public mutating func next() -> Element? {
        guard !ys.isEmpty else {
            return nil
        }

        guard let someX = x else {
            return nil
        }

        guard let someY = yIt.next() else {
            yIt = ys.makeIterator()
            x = xs.next()
            return next()
        }

        return (someX, someY)
    }
}
