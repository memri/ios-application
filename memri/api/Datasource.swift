//
//  Datasource.swift
//  memri
//
//  Created by Koen van der Veen on 25/05/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import RealmSwift


protocol UniqueString {
    var uniqueString:String { get }
}

public class Datasource: Object, UniqueString {
    /// Retrieves the query which is used to load data from the pod
    @objc dynamic var query: String? = nil
    
    /// Retrieves the property that is used to sort on
    @objc dynamic var sortProperty: String? = nil
    
    /// Retrieves whether the sort direction
    /// false sort descending
    /// true sort ascending
    let sortAscending = RealmOptional<Bool>()
    /// Retrieves the number of items per page
    let pageCount = RealmOptional<Int>() // Todo move to ResultSet
 
    let pageIndex = RealmOptional<Int>() // Todo move to ResultSet
     /// Returns a string representation of the data in QueryOptions that is unique for that data
     /// Each QueryOptions object with the same data will return the same uniqueString
    var uniqueString:String {
        var result:[String] = []
        
        result.append((self.query ?? "").sha256())
        result.append(self.sortProperty ?? "")
        
        let sortAsc = self.sortAscending.value ?? true
        result.append(String(sortAsc))
            
        return result.joined(separator: ":")
    }
    
    init(query:String) {
        super.init()
        self.query = query
    }
    
    required init() {
        super.init()
    }
    
    public class func fromCVUDefinition(_ def:CVUParsedDatasourceDefinition,
                                        _ viewArguments: ViewArguments?) throws -> Datasource {
        
        func getValue<T>(_ name:String) throws -> T? {
            if let expr = def[name] as? Expression{
                do {
                    let x:T? = try expr.execForReturnType(viewArguments)
                    return x
                }
                catch let error {
                    debugHistory.warn("\(error)")
                    return nil
                }
            }
            return def[name] as? T
        }
        
        return Datasource(value: [
            "selector": def.selector ?? "[datasource]",
            "query": try getValue("query") ?? "",
            "sortProperty": try getValue("sortProperty") ?? "",
            "sortAscending": try getValue("sortAscending") ?? true
        ])
    }
}

public class CascadingDatasource: Cascadable, UniqueString {
    /// Retrieves the query which is used to load data from the pod
    var query: String? {
        datasource.query ?? cascadeProperty("query")
    }
    
    /// Retrieves the property that is used to sort on
    var sortProperty: String? {
        datasource.sortProperty ?? cascadeProperty("sortProperty")
    }
    
    /// Retrieves whether the sort direction
    /// false sort descending
    /// true sort ascending
    var sortAscending:Bool? {
        datasource.sortAscending.value ?? cascadeProperty("sortAscending")
    }
    
    let datasource:Datasource
 
     /// Returns a string representation of the data in QueryOptions that is unique for that data
     /// Each QueryOptions object with the same data will return the same uniqueString
    var uniqueString:String {
        var result:[String] = []
        
        result.append((self.query ?? "").sha256())
        result.append(self.sortProperty ?? "")
        
        let sortAsc = self.sortAscending ?? true
        result.append(String(sortAsc))
            
        return result.joined(separator: ":")
    }
    
    func flattened() -> Datasource {
        return Datasource(value: [
            "query": self.query as Any,
            "sortProperty": self.sortProperty as Any,
            "sortAscending": self.sortAscending as Any
        ])
    }
    
    init(_ cascadeStack: [CVUParsedDatasourceDefinition],
         _ viewArguments: ViewArguments,
         _ datasource:Datasource) {
        
        self.datasource = datasource
        super.init(cascadeStack, viewArguments)
    }
    
    subscript(propName:String) -> Any? {
        get {
            switch (propName) {
            case "query": return query
            case "sortProperty": return sortProperty
            case "sortAscending": return sortAscending
            default: return nil
            }
        }
        set (value) {
            switch (propName) {
            case "query": return datasource.query = value as? String ?? ""
            case "sortProperty": return datasource.sortProperty = value as? String ?? ""
            case "sortAscending": return datasource.sortAscending.value = value as? Bool ?? true
            default: return
            }
        }
    }
}


