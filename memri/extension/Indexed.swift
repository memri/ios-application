//
//  Indexed.swift
//  MemriPlayground
//
//  Created by Toby Brennan on 5/6/20.
//  Copyright © 2020 Memri. All rights reserved.
//


// Copyright Apptekstudios 2020
// https://blog.apptekstudios.com/2020/05/working-with-arrays-in-swiftui/

import Foundation

@dynamicMemberLookup
struct Indexed<Element, Index> {
    var index: Index
    var offset: Int
    var element: Element

    // Access to constant members
    subscript<T>(dynamicMember keyPath: KeyPath<Element, T>) -> T {
        element[keyPath: keyPath]
    }

    // Access to mutable members
    subscript<T>(dynamicMember keyPath: WritableKeyPath<Element, T>) -> T {
        get { element[keyPath: keyPath] }
        set { element[keyPath: keyPath] = newValue }
    }
}

extension Indexed: Identifiable where Element: Identifiable {
    var id: Element.ID { element.id }
}

extension RandomAccessCollection {
    func indexed() -> AnyRandomAccessCollection<Indexed<Element, Index>> {
        AnyRandomAccessCollection(
            zip(zip(indices, 0...).lazy, self).lazy
                .map { Indexed(index: $0.0.0, offset: $0.0.1, element: $0.1) }
        )
    }
}
