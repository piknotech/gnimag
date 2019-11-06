//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// Color represents a simple RGB color.
/// The channel values are in the range [0, 1].
public struct Color {
    public let red: Double
    public let green: Double
    public let blue: Double
    
    /// Default initializer.
    @_transparent
    public init(_ red: Double, _ green: Double, _ blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
    
    /// The euclidean distance between this color and another color.
    /// 0 means that the colors are equal. 1 means that the difference is maximal.
    /// TODO: vlt. schnellere difference funktion benutzen
    @_transparent
    public func distance(to color: Color) -> Double {
        let diff0 = red - color.red
        let diff1 = green - color.green
        let diff2 = blue - color.blue
        
        return sqrt((diff0 * diff0 + diff1 * diff1 + diff2 * diff2) / 3)
    }

    // MARK: Static members
    public static let white = Color(1, 1, 1)
    public static let black = Color(0, 0, 0)
    public static let blue = Color(0, 0, 1)
    public static let green = Color(0, 1, 0)
    public static let yellow = Color(1, 1, 0)
    public static let red = Color(1, 0, 0)
}

extension Color: Equatable {
    /// Compare two color instances.
    public static func ==(lhs: Color, rhs: Color) -> Bool {
        return lhs.red == rhs.red && lhs.green == rhs.green && lhs.blue == rhs.blue
    }
}

// MARK: Color Arithmetic
extension Color {
    /// Zero (black) color.
    public static let zero = Color(0, 0, 0)

    /// Add two colors.
    public static func +(lhs: Color, rhs: Color) -> Color {
        return Color(lhs.red + rhs.red, lhs.green + rhs.green, lhs.blue + rhs.blue)
    }

    /// Subtract two colorrs.
    public static func -(lhs: Color, rhs: Color) -> Color {
        return Color(lhs.red - rhs.red, lhs.green - rhs.green, lhs.blue - rhs.blue)
    }

    /// Negate a color (mirror it at zero).
    /// This is NOT the complementary color; use "Color.white - color" to negate "color".
    public static prefix func -(a: Color) -> Color {
        return Color(-a.red, -a.green, -a.blue)
    }

    /// Multiply a color by a scalar.
    public static func *(lhs: Double, rhs: Color) -> Color {
        return Color(lhs * rhs.red, lhs * rhs.green, lhs * rhs.blue)
    }

    /// Divide a color by a scalar.
    public static func /(lhs: Color, rhs: Double) -> Color {
        return Color(lhs.red / rhs, lhs.green / rhs, lhs.blue / rhs)
    }
}
