//
//  Created by David Knothe on 22.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// Color represents a simple RGB color.
/// The channel values are in the range [0, 1].

public struct Color: Equatable {
    public let red: Double
    public let green: Double
    public let blue: Double
    
    /// Default initializer.
    public init(_ red: Double, _ green: Double, _ blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
    
    // MARK: - Equatable
    
    /// Compare two color instances.
    public static func ==(lhs: Color, rhs: Color) -> Bool {
        return lhs.red == rhs.red && lhs.green == rhs.green && lhs.blue == rhs.blue
    }
    
    /// The euclidian distance between this color and another color.
    /// 0 means the colors are equal. 1 means that the difference is maximal.
    /// TODO: vlt. schnellere difference funktion benutzen
    public func euclideanDifference(to color: Color) -> Double {
        let diff0 = red - color.red
        let diff1 = green - color.green
        let diff2 = blue - color.blue
        
        return ((diff0 * diff0 + diff1 * diff1 + diff2 * diff2) / 3).squareRoot()
    }
    
    // MARK: - Static members
    
    /// White color.
    public static let white = Color(1, 1, 1)
    
    /// Black color.
    public static let black = Color(0, 0, 0)
}
