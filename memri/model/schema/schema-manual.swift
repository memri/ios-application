//
// schema-manual.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation

// MARK: USE THIS FOR CHANGES TO SCHEMA FOR IOS THAT AREN'T YET REFLECTED IN THE MAIN SCHEMA.

//// ADD ME TO LABEL FAMILY:
// case typeLabelAnnotation = "LabelAnnotation"
// case typeLabelAnnotationCollection = "LabelAnnotationCollection"
// case typePhotoAnnotation = "PhotoAnnotation"

/// An annotation on another type.
public class LabelAnnotation: Item {
    /// The type of label this represents
    @objc dynamic var labelType: String?

    /// The labels for this type
    @objc dynamic var labels: String?

    @objc dynamic var allowSharing: Bool = true

    var annotatedItem: Item? {
        edges("annotatedItem")?.items()?.first
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            labelType = try decoder.decodeIfPresent("name")
            labels = try decoder.decodeIfPresent("labels")
            allowSharing = try decoder.decodeIfPresent("allowSharing") ?? true

            try self.superDecode(from: decoder)
        }
    }
}

extension LabelAnnotation { // An accessor
    var labelsSet: Set<String> {
        get { Set(labels?.split(separator: ",").map(String.init) ?? []) }
        set { labels = newValue.isEmpty ? nil : newValue.joined(separator: ",") }
    }
}

/// A group of annotations. This could be used for making a collection of annotations to share for ML training.
public class LabelAnnotationCollection: Item {
    var annotations: [LabelAnnotation]? {
        edges("annotations")?.itemsArray()
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            try self.superDecode(from: decoder)
        }
    }
}

/// An annotation on a photo
public class PhotoAnnotation: Item {
    /// The x-coordinate of the top-left point, as a fraction of image width (0-1)
    @objc dynamic var x: Double = 0
    /// The y-coordinate of the top-left point, as a fraction of image height (0-1)
    @objc dynamic var y: Double = 0
    /// The width of the bounding-box, as a fraction of image width (0-1)
    @objc dynamic var width: Double = 0
    /// The height of the bounding-box, as a fraction of image height (0-1)
    @objc dynamic var height: Double = 0

    /// A label that this rectangle represents
    var annotationLabel: String?

    /// An item that this rectangle represents
    var annotationLinkedItem: Item? {
        edges("annotationLinkedItem")?.items()?.first
    }

    /// The photo that this annotation belongs to
    var annotatedPhoto: Photo? {
        edges("annotatedPhoto")?.items()?.first
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        jsonErrorHandling(decoder) {
            x = try decoder.decode("x")
            y = try decoder.decode("y")
            width = try decoder.decode("width")
            height = try decoder.decode("height")
            annotationLabel = try decoder.decodeIfPresent("annotationLabel")

            try self.superDecode(from: decoder)
        }
    }
}
