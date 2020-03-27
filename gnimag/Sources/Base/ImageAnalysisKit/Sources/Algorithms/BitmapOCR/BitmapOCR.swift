//
//  Created by David Knothe on 21.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Image

/// BitmapOCR performs character recognition by comparing images to a concrete dataset and returning the character from the set which fitted the image most.
/// Use BitmapOCRCreator to create such a dataset.
/// Attention: BitmapOCR can only read single lines of text at once.
public final class BitmapOCR {
    /// The location of the dataset directory.
    private let location: String

    /// The user-provided configuration, if existing.
    private let config: OCRConfig?

    /// The full OCR dataset.
    private var dataset: Dataset
    private struct Dataset {
        /// The size of each image.
        let imageSize: (width: Int, height: Int)

        /// All characters that can be recognized.
        /// All images inside this dataset have the same size.
        let characters: [Character]
        struct Character {
            let image: Image
            let string: String
            let aspectRatio: Double // = width / height
        }
    }

    /// Default initializer.
    public init(location: String, configFileDirectory: String? = nil) {
        self.location = location
        config = OCRConfig.from(file: (configFileDirectory ?? location) +/ "ocr.json")
        dataset = Self.readDataset(from: location, using: config)
    }

    /// Recognize characters inside an image; return the characters sorted left-to-right.
    /// The image must only consist of a single line of text.
    /// Returns nil if one of the characters could not be recognized.
    public func recognize(image: Image, textColor: ColorMatch) -> [String]? {
        let components = ConnectedComponents.in(image, color: textColor, connectivity: .eight, combineComponents: ComponentCombinationStrategy.verticalOverlay(requiredOverlap: 0.5))

        // Recognize each character; if one character is not recognized, terminate early and return nil
        var result = [String]()
        for component in components {
            guard let character = recognize(component: component) else { return nil }
            result.append(character)
        }

        return result
    }

    /// Recognize a single component by comparing it to every character in the dataset.
    private func recognize(component: OCRComponent) -> String? {
        let originalAspectRatio = Double(component.region.width) / Double(component.region.height)
        let scaledImage = component.CGImage.scaled(toWidth: dataset.imageSize.width, height: dataset.imageSize.height, mode: .aspectFitCenter)

        // Compare to every image with a similar aspect ratio
        var possibleMatches = [(Dataset.Character, Double)]()
        for character in dataset.characters {
            if !ratiosAreSimilar(character.aspectRatio, originalAspectRatio) { continue }

            // Pixel-by-pixel compare
            let identicality = scaledImage.identicality(to: character.image)
            possibleMatches.append((character, identicality))
        }

        // Find best match
        guard let best = (possibleMatches.max { $0.1 < $1.1 }) else {
            Terminal.log(.warning, "BitmapOCR – character with aspect ratio \(originalAspectRatio) doesn't match any character in the dataset!")
            return nil
        }

        if best.1 < 0.8 {
            Terminal.log(.warning, "BitmapOCR – character match with \"\(best.0.string)\" only has a confidence of \(best.1)!")
        }

        return best.0.string
    }

    /// Check whether two ratios approximately have the same magnitude.
    /// The larger the ratios, the more deviation is allowed.
    private func ratiosAreSimilar(_ ratio1: Double, _ ratio2: Double) -> Bool {
        let largestMagnitude = max(ratio1, 1 / ratio1, ratio2, 1 / ratio2) // >= 1
        let deviation = 1.3 + 0.2 * sqrt(largestMagnitude) // Function values: [1: 1.5, 4: 1.7, 9: 1.9]
        return (1/deviation ... deviation).contains(ratio1 / ratio2)
    }

    // MARK: Reading OCR Dataset

    /// Read an OCR dataset from a directory.
    private static func readDataset(from directory: String, using config: OCRConfig?) -> Dataset {
        // Read every .png image inside the directory
        let url = URL(fileURLWithPath: directory)
        guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            exit(withMessage: "BitmapOCR – couldn't read contents of directory \(directory)!")
        }

        let pngFiles = contents.filter { $0.pathExtension == "png" }
        if pngFiles.isEmpty {
            exit(withMessage: "BitmapOCR – There are no PNG files!")
        }

        let imagesAndNames = pngFiles.compactMap { url -> (CGImage, String) in
            let filename = url.deletingPathExtension().lastPathComponent
            let character = config?.mappings[filename] ?? filename
            guard let image = CGImage.from(path: url.path) else {
                exit(withMessage: "BitmapOCR – Couldn't read image \(url.path)!")
            }
            return (image, character)
        }

        // Find suitable common image size
        let width = imagesAndNames.map { $0.0.width }.max() ?? 0
        let height = imagesAndNames.map { $0.0.height }.max() ?? 0

        return Dataset(
            imageSize: (width, height),
            characters: imagesAndNames.map { (image, name) in
                let ratio = Double(image.width) / Double(image.height)
                let scaled = image.scaled(toWidth: width, height: height, mode: .aspectFitCenter)
                return BitmapOCR.Dataset.Character(image: scaled, string: name, aspectRatio: ratio)
            }
        )
    }
}
