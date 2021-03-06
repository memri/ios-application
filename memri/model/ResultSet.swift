//
// ResultSet.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation

/// This class wraps a query and its results, and is responsible for loading a the result and possibly applying clienside filtering
public class ResultSet: ObservableObject {
    /// Object describing the query and postprocessing instructions
    var datasource: Datasource
    /// Resulting Items
    var items: [Item] = []
    /// Nr of items in the resultset
    var count: Int = 0
    /// Boolean indicating whether the Items in the result are currently being loaded
    var isLoading: Bool = false

    /// Unused, Experimental
    private var pages: [Int] = []
    private let cache: Cache
    private var _filterText: String?
    private var _unfilteredItems: [Item]?

    /// Computes the type of the data items being requested via the query
    /// Returns "mixed" when data items of multiple types can be returned
    var determinedType: String? {
        // TODO: implement (more) proper query language (and parser)

        if let query = datasource.query, query != "" {
            if let typeName = query.split(separator: " ").first {
                return String(typeName == "*" ? "mixed" : typeName)
            }
        }

        var foundType: String?
        for item in items {
            if let _ = foundType {
                if foundType == item.genericType { continue }
                else { return "mixed" }
            }
            else {
                foundType = item.genericType
            }
        }

        return foundType
    }

    /// Boolean indicating whether the resultset is a collection of items or a single item
    var isList: Bool {
        // TODO: change this to be a proper query parser
        // TODO: this is called very often, needs caching

        let (typeName, filter) = cache.parseQuery(datasource.query ?? "")
        if let _ = ItemFamily(rawValue: typeName) {
            if (filter ?? "").match("^AND uid = .*?$").count > 0 {
                return false
            }
        }

        return true
    }

    /// Get the only item from the resultset if the set has size 1, else return nil. Note that
    ///  [singleton](https://en.wikipedia.org/wiki/Singleton_(mathematics)) is here in the mathematical sense.
    var singletonItem: Item? {
        get {
            if !isList, count > 0 { return items[0] }
            else { return nil }
        } set(newValue) {}
    }

    /// Text used to filter queries
    var filterText: String? {
        get {
            _filterText
        }
        set {
            if _filterText != newValue {
                _filterText = newValue?.nilIfBlankOrSingleLine
                filter()
            }
        }
    }

    required init(_ ch: Cache, _ datasource: Datasource) {
        cache = ch
        self.datasource = datasource
    }

    /// Executes a query given the current QueryOptions, filters the result client side and executes the callback on the resulting
    ///  Items
    /// - Parameter callback: Callback with params (error: Error, result: [Item]) that is executed on the returned result
    /// - Throws: empty query error
    func load(
        syncWithRemote: Bool = true,
        _ callback: @escaping (_ error: Error?) throws -> Void
    ) throws {
        if !isLoading {
            if datasource.query == "" {
                throw "Exception: No query specified when loading result set"
            }

            isLoading = true

            updateUI()

            try cache.query(datasource, syncWithRemote: syncWithRemote) { (error, result) -> Void in
                if let result = result {
                    self.items = result
                    self.count = self.items.count

                    if self._unfilteredItems != nil {
                        self._unfilteredItems = nil
                        self.filter()
                    }

                    // We've successfully loaded page 0
                    self.setPagesLoaded(0) // TODO: This is not used at the moment

                    self.isLoading = false

                    try callback(nil)
                }
                else if error != nil {
                    self.isLoading = false

                    try callback(error)
                }

                self.updateUI()
            }
        }
    }

    /// Force update the items property, recompute the counts and reapply filters
    /// - Parameter result: the new items
    func reload() throws {
        try load(syncWithRemote: false) { _ in }
    }

    private func updateUI() {
        objectWillChange.send() // TODO: create our own publishers
    }

    /// Apply client side filter using the FilterText , with a fallback to the server
    public func filter() {
        // Cancel filtering
        if let filter = _filterText {
            // Filter using _filterText
            var filterResult: [Item] = []

            // Filter through items
            let searchSet = _unfilteredItems ?? items
            if searchSet.count > 0 {
                for i in 0 ... searchSet.count - 1 {
                    if searchSet[i].hasProperty(filter) {
                        filterResult.append(searchSet[i])
                    }
                }
            }

            // Store the items of this resultset
            if _unfilteredItems == nil { _unfilteredItems = items }

            // Set the filtered result
            items = filterResult
            count = filterResult.count
        }
        else {
            // If we filtered before...
            if let _unfilteredItems = _unfilteredItems {
                // Put back the items of this resultset
                items = _unfilteredItems
                count = _unfilteredItems.count
            }
        }

        objectWillChange.send() // TODO: create our own publishers
    }

    /// Executes the query again
    public func reload(_: ResultSet) {
        // Reload all pages
        //        for (page, _) in searchResult.pages {
        //            let _ = self.loadPage(searchResult, page, { (error) in })
        //        }
    }

    /// - Remark: currently unused
    /// - Todo: Implement
    /// - Parameter options:
    public func resort(_: Datasource) {}

    /// Mark page with pageIndex as index as loaded
    /// - Parameter pageIndex: index of the page to mark as loaded
    func setPagesLoaded(_ pageIndex: Int) {
        if !pages.contains(pageIndex) {
            pages.append(pageIndex)
        }
    }
}
