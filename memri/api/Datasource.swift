//
// Datasource.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import RealmSwift

protocol UniqueString {
    var uniqueString: String { get }
}

public class Datasource: Equatable, UniqueString {
    public static func == (lhs: Datasource, rhs: Datasource) -> Bool {
        lhs.uniqueString == rhs.uniqueString
    }

    /// Retrieves the query which is used to load data from the pod
    var query: String?

    /// Retrieves the property that is used to sort on
    var sortProperty: String?

    /// Retrieves whether the sort direction
    /// - false sort descending
    /// - true sort ascending
    var sortAscending: Bool?
    /// Retrieves the number of items per page
    var pageCount: Int?

    var pageIndex: Int?
    /// Returns a string representation of the data in QueryOptions that is unique for that data
    /// Each QueryOptions object with the same data will return the same uniqueString
    var uniqueString: String {
        var result: [String] = []

        result.append((query ?? "").sha256())
        result.append(sortProperty ?? "")

        let sortAsc = sortAscending ?? true
        result.append(String(sortAsc))

        return result.joined(separator: ":")
    }

    init(query: String?, sortProperty: String? = nil, sortAscending: Bool? = nil) {
        self.query = query
        self.sortProperty = sortProperty
        self.sortAscending = sortAscending
    }
}

public class CascadingDatasource: Cascadable, UniqueString, Subscriptable {
    /// Retrieves the query which is used to load data from the pod
    var query: String? {
        get { cascadeProperty("query") }
        set(value) { setState("query", value) }
    }

    /// Retrieves the property that is used to sort on
    var sortProperty: String? {
        get { cascadeProperty("sortProperty") }
        set(value) { setState("sortProperty", value) }
    }

    /// Retrieves whether the sort direction
    /// false sort descending
    /// true sort ascending
    var sortAscending: Bool? {
        get { cascadeProperty("sortAscending") }
        set(value) { setState("sortAscending", value) }
    }

    /// Returns a string representation of the data in QueryOptions that is unique for that data
    /// Each QueryOptions object with the same data will return the same uniqueString
    var uniqueString: String {
        var result: [String] = []

        result.append((query ?? "").sha256())
        result.append(sortProperty ?? "")

        let sortAsc = sortAscending ?? true
        result.append(String(sortAsc))

        return result.joined(separator: ":")
    }

    func flattened() -> Datasource {
        Datasource(
            query: query,
            sortProperty: sortProperty,
            sortAscending: sortAscending
        )
    }

    subscript(propName: String) -> Any? {
        get {
            switch propName {
            case "query": return query
            case "sortProperty": return sortProperty
            case "sortAscending": return sortAscending
            default: return nil
            }
        }
        set(value) {
            switch propName {
            case "query": query = value as? String
            case "sortProperty": sortProperty = value as? String
            case "sortAscending": sortAscending = value as? Bool
            default: return
            }
        }
    }
}
