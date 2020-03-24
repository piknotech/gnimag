//
//  Created by David Knothe on 22.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Image

/// Use BitmapOCRCreator to create or extend an existing OCR dataset.
/// Attention: Only use single lines of text as input.
public final class BitmapOCRCreator {
    /// The directory where detected character images will be written to.
    private let outputDirectory: String

    /// Default initializer.
    public init(outputDirectory: String) {
        self.outputDirectory = outputDirectory
    }

    /// Extract all components from an image and save them in the directory.
    /// FilenameBase must end in ".png".
    public func addComponents(from image: Image, textColor: ColorMatch, filenameBase: String) {
        let components = ConnectedComponents.in(image, color: textColor, connectivity: .eight, combineComponents: ComponentCombinationStrategy.verticalOverlay(requiredOverlap: 0.5))

        for component in components {
            nonoverwritingSave(image: component.CGImage, to: outputDirectory +/ filenameBase)
        }
    }

    /// Extract all components from an image and save them in the directory.
    /// The components are sorted top-down, left-to-right and named by the expected characters. expectedCharacters contains the character names, separated by spaces.
    public func addComponents(from image: Image, textColor: ColorMatch, expectedCharacters: String) {
        var components = ConnectedComponents.in(image, color: textColor, connectivity: .eight, combineComponents: ComponentCombinationStrategy.verticalOverlay(requiredOverlap: 0.5))

        // Sort by center point
        components.sort { a, b in
            // If one of the center points in contained vertically in the other's range, they are vertically on the same level. Then, sort by left-to-right
            let aRange = a.region.yRange, bRange = b.region.yRange
            if aRange.contains(bRange.center) || bRange.contains(aRange.center) {
                return a.region.xRange.center < b.region.xRange.center // Left-to-right
            } else {
                return aRange.center > bRange.center // Top-to-bottom (attention: flipped because of LLO)
            }
        }

        var characters = expectedCharacters.split(separator: " ")

        // Pad missing component names with "unmatched_component", if necessary
        if components.count > characters.count {
            Terminal.log(.warning, "OCRCreator – Character mismatch: \(characters.count) characters expected, but \(components.count) found. Unmatched components will be saved as \"unmatched.png\"")
            characters.append(contentsOf: repeatElement("unmatched", count: components.count - characters.count))
        } else if components.count < characters.count {
            Terminal.log(.warning, "OCRCreator – Character mismatch: \(characters.count) characters expected, but \(components.count) found.")
        }

        for (component, character) in zip(components, characters) {
            nonoverwritingSave(image: component.CGImage, to: outputDirectory +/ "\(character).png")
        }
    }

    /// Save an image in an nonoverwriting style, i.e. adapt the filename if it is already taken.
    /// This means, when the filename is taken, the first free filename of the form `filename (n)`, where n >= 2, is used.
    private func nonoverwritingSave(image: CGImage, to path: String) {
        // Get relevant path components
        let url = URL(string: path)!
        let directory = url.deletingLastPathComponent().absoluteString
        let filename = NSString(string: url.lastPathComponent).deletingPathExtension
        let pathExtension = url.pathExtension

        // Find first free filename
        var suggestion = url.lastPathComponent
        var index = 2
        while FileManager.default.fileExists(atPath: directory +/ suggestion) {
            suggestion = String(format: "%@ (%d).%@", filename, index, pathExtension)
            index += 1
        }

        image.write(to: directory +/ suggestion)
    }
}
