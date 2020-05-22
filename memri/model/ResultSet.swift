//
//  ResultSet.swift
//  memri
//
//  Created by Ruben Daniels on 5/22/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

/// This class wraps a query and its results, and is responsible for loading a the result and possibly applying clienside filtering
public class ResultSet: ObservableObject {
 
    /// Object describing the query and postprocessing instructions
    var queryOptions: QueryOptions = QueryOptions(query: "")
    /// Resulting DataItems
    var items: [DataItem] = []
    /// Nr of items in the resultset
    var count: Int = 0
    /// Boolean indicating whether the DataItems in the result are currently being loaded
    var isLoading: Bool = false
    
    /// Unused, Experimental
    private var pages: [Int] = []
    private let cache: Cache
    private var _filterText: String = ""
    private var _unfilteredItems: [DataItem]? = nil
 
    /// Computes a string representation of the resultset
    var determinedType: String? {
        // TODO implement (more) proper query language (and parser)
        
        if let query = self.queryOptions.query, query != "" {
            if let typeName = query.split(separator: " ").first {
                return String(typeName == "*" ? "mixed" : typeName)
            }
        }
        return nil
    }

    /// Boolean indicating whether the resultset is a collection of items or a single item
    var isList: Bool {
        // TODO change this to be a proper query parser
        
        let (typeName, filter) = cache.parseQuery((self.queryOptions.query ?? ""))
        
        if let type = DataItemFamily(rawValue: typeName) {
            let primKey = type.getPrimaryKey()
            if (filter ?? "").match("^AND \(primKey) = '.*?'$").count > 0 {
                return false
            }
        }
        
        return true
    }
 
    /// Get the only item from the resultset if the set has size 1, else return nil. Note that
    ///  [singleton](https://en.wikipedia.org/wiki/Singleton_(mathematics)) is here in the mathematical sense.
    var singletonItem: DataItem? {
        get{
            if !isList && count > 0 { return items[0] }
            else { return nil }
        } set (newValue){
            
        }
    }
 
    /// Text used to filter queries
    var filterText: String {
        get {
            return _filterText
        }
        set (newFilter) {
            _filterText = newFilter
            filter()
        }
    }
    
    required init(_ ch:Cache) {
        cache = ch
    }
    
    /// Executes a query given the current QueryOptions, filters the result client side and executes the callback on the resulting
    ///  DataItems
    /// - Parameter callback: Callback with params (error: Error, result: [DataItem]) that is executed on the returned result
    /// - Throws: empty query error
    func load(_ callback:(_ error:Error?) -> Void) throws {
        
        // Only execute one loading process at the time
        if !isLoading {
        
            // Validate queryOptions
            if queryOptions.query == "" {
                throw "Exception: No query specified when loading result set"
            }
            
            // Set state to loading
            isLoading = true
            
            // Make sure the loading state is updated in the UI
            updateUI()
        
            // Execute the query
            cache.query(queryOptions) { (error, result) -> Void in
                if let result = result {
                    
                    // Set data and count
                    items = result
                    count = items.count
                    
                    // Resapply filter
                    if _unfilteredItems != nil {
                        _unfilteredItems = nil
                        filter()
                    }

                    // We've successfully loaded page 0
                    setPagesLoaded(0) // TODO This is not used at the moment

                    // First time loading is done
                    isLoading = false

                    // Done
                    callback(nil)
                }
                else if (error != nil) {
                    // Set loading state to error
                    isLoading = false

                    // Done with errors
                    callback(error)
                }
                
                // Make sure the loading state is updated in the UI
                updateUI()
            }
        }
    }
    
    /// Force update the items property, recompute the counts and reapply filters
    /// - Parameter result: the new items
    func forceItemsUpdate(_ result:[DataItem]) {
        
        // Set data and count
        items = result
        count = items.count

        // Resapply filter
        if _unfilteredItems != nil {
            _unfilteredItems = nil
            filter()
        }
        
        updateUI()
    }
    
    private func updateUI(){
        self.objectWillChange.send() // TODO create our own publishers
    }

    /// Apply client side filter using the FilterText , with a fallback to the server
    public func filter() {
        // Cancel filtering
        if _filterText == "" {
            
            // If we filtered before...
            if let _unfilteredItems = _unfilteredItems{
                
                // Put back the items of this resultset
                items = _unfilteredItems
                count = _unfilteredItems.count
            }
        }
            
        // Filter using _filterText
        else {
            // Array to store filter results
            var filterResult:[DataItem] = []
            
            // Filter through items
            let searchSet = _unfilteredItems ?? items
            if searchSet.count >  0 {
                for i in 0...searchSet.count - 1 {
                    if searchSet[i].hasProperty(_filterText) {
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
        
        self.objectWillChange.send() // TODO create our own publishers
    }
        
    /// Executes the query again
    public func reload(_ searchResult:ResultSet) -> Void {
        // Reload all pages
//        for (page, _) in searchResult.pages {
//            let _ = self.loadPage(searchResult, page, { (error) in })
//        }
    }
    
    
    /// - Remark: currently unused
    /// - Todo: Implement
    /// - Parameter options:
    public func resort(_ options:QueryOptions) {
        
    }
    
    /// Mark page with pageIndex as index as loaded
    /// - Parameter pageIndex: index of the page to mark as loaded
    func setPagesLoaded(_ pageIndex:Int) {
        if !pages.contains(pageIndex) {
            pages.append(pageIndex)
        }
    }
}
