//
//  SessionView.swift
//  memri
//
//  Created by Koen van der Veen on 29/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

//public struct DataItemReference {
//    let type: DataItemFamily
//    let uid: String
//
//    init(type:DataItemFamily, uid:String) {
//        self.type = type
//        self.uid = uid
//    }
//
//    init(dataItem:DataItem) {
//        type = DataItemFamily(rawValue: dataItem.genericType)! // TODO refactor: error handling
//        uid = dataItem.uid
//    }
//}

public class UserState: Object {
    @objc dynamic var uid: String = DataItem.generateUUID()
    
    let state:String = ""
    
    subscript<T>(propName:String) -> T? {
        get {
            var x:[String:Any]?
            do { x = try InMemoryObjectCache.get(uid) as? [String:Any] } catch { return nil } // TODO refactor: handle error
            do { if x == nil { x = try transformToDict() } } catch { return nil } // TODO refactor: handle error
            
            if T.self == DataItem.self {
                if let lookup = x?[propName] as? [String:Any] {
                    if let type = DataItemFamily(rawValue: lookup["type"] as! String) {
                        let x:DataItem? = realm?.object(
                            ofType: DataItemFamily.getType(type)() as! DataItem.Type,
                            forPrimaryKey: lookup["uid"] as! String)
                        return x as? T
                    }
                }
                
                return nil
            }
            
            return x?[propName] as? T
        }
        set(newValue) {
            var x:[String:Any]?
            do { x = try InMemoryObjectCache.get(uid) as? [String:Any] } catch { return } // TODO refactor: handle error
            do { if x == nil { x = try transformToDict() } } catch { return } // TODO refactor: handle error
            
            if let newValue = newValue as? DataItem {
                x?[propName] = ["type": newValue.genericType, "uid": newValue.uid]
            }
            else {
                x?[propName] = newValue
            }
            
            try? globalInMemoryObjectCache.set(uid, x)
            
            scheduleWrite()
        }
    }
    
    private func transformToDict() throws -> [String:Any]{
        let dict:[String:AnyDecodable] = unserialize(state)
        try InMemoryObjectCache.set(self.uid, dict as [String:Any])
        return dict
    }
    
    var scheduled = false
    private func scheduleWrite(){
        // Don't schedule when we are already scheduled
        if !scheduled {
            
            // Prevent multiple calls to the dispatch queue
            scheduled = true
            
            // Schedule update
            DispatchQueue.main.async {
                
                // Reset scheduled
                self.scheduled = false
                
                // Update UI
                self.persist()
            }
        }
    }
    
    private func persist() {
        if self.realm == nil { return }
        
        do {
            if let x = try InMemoryObjectCache.get(uid) as? [String : Any] {
                realmWriteIfAvailable(self.realm) {
                    self["state"] = serialize(AnyCodable(x))
                }
            }
        }
        catch {
            // TODO refactor: Log error
        }
    }
    
    // Requires support for dataItem lookup.
    
    public func toggleState(_ stateName:String) {
        let x:Bool = self[stateName] as? Bool ?? true
        self[stateName] = !x
    }

    public func hasState(_ stateName:String) -> Bool {
        let x:Bool = self[stateName] ?? false
        return x
    }
}
public typealias ViewArguments = UserState
    
public class SessionView: DataItem {
 
    override var genericType:String { "sessionview" }
 
    @objc dynamic var name: String? = nil
    @objc dynamic var viewDefinition: ViewDSLDefinition? = nil
    @objc dynamic var userState: UserState? = nil
    @objc dynamic var viewArguments: ViewArguments? = nil
    @objc dynamic var queryOptions: QueryOptions? = nil // TODO refactor: fix cascading
    @objc dynamic var session: Session? = nil
    
    override var computedTitle:String {
//        if let value = self.name ?? self.title { return value }
//        else if let rendererName = self.rendererName {
//            return "A \(rendererName) showing: \(self.queryOptions?.query ?? "")"
//        }
//        else if let query = self.queryOptions?.query {
//            return "Showing: \(query)"
//        }
        return "[No Name]"
    }
    
    required init(){
        super.init()
        
        self.functions["computedDescription"] = {_ in
            print("MAKE THIS DISSAPEAR")
            return self.computedTitle
        }
    }
}
