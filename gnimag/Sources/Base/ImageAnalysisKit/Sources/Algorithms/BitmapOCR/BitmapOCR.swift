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
    public init(location: String) {
        self.location = location
        config = OCRConfig.from(file: location +/ "ocr.json")
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
            if !(0.8 ... 1.2).contains(character.aspectRatio / originalAspectRatio) { continue }

            // Pixel-by-pixel compare
            let identicality = scaledImage.identicality(to: character.image)
            if identicality > 85% {
                possibleMatches.append((character, identicality))
            }
        }

        // Return best match
        return possibleMatches.sorted { $0.1 > $1.1 }.first?.0.string
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
