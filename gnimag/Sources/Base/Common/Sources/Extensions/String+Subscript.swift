//
//  Created by David Knothe on 02.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//
// Taken from https://stackoverflow.com/a/26775912/3910407

public extension String {
    var length: Int {
        count
    }

    /// Get the i'th character of the string.
    subscript(i: Int) -> String {
        self[i ..< i + 1]
    }

    /// Get the suffix beginning at the given index.
    func substring(fromIndex: Int) -> String {
        self[min(fromIndex, length) ..< length]
    }

    /// Get the prefix to the, but not including, the given index.
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    /// Perform a range subscript.
    subscript(r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}
