//
//  schema-manual.swift
//  memri
//
//  Created by Toby Brennan on 27/8/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

// MARK: USE THIS FOR CHANGES TO SCHEMA FOR IOS THAT AREN'T YET REFLECTED IN THE MAIN SCHEMA.


//// ADD ME TO LABEL FAMILY:
//case typeLabelAnnotation = "LabelAnnotation"
//case typeLabelAnnotationCollection = "LabelAnnotationCollection"

/// An annotation on another type.
public class LabelAnnotation : Item {
    
    /// The type of label this represents
    @objc dynamic var labelType: String? = nil
    
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
            
            try self.superDecode(from: decoder)
        }
    }
}

extension LabelAnnotation {// An accessor
    var labelsSet: Set<String> {
        get { Set(labels?.split(separator: ",").map(String.init) ?? []) }
        set { labels = newValue.isEmpty ? nil : newValue.joined(separator: ",") }
    }
}


/// A group of annotations. This could be used for making a collection of annotations to share for ML training.
public class LabelAnnotationCollection : Item {
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
