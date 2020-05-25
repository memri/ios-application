//
//  UserState.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

public class UserState: Object {
    @objc dynamic var uid: String = DataItem.generateUUID()
    
    let state:String = ""
    
    subscript<T>(propName:String) -> T? {
        get {
            let x = self.asDict()
            
            if T.self == DataItem.self {
                if let lookup = x[propName] as? [String:Any] {
                    if let type = DataItemFamily(rawValue: lookup["type"] as! String) {
                        let x:DataItem? = realm?.object(
                            ofType: DataItemFamily.getType(type)() as! DataItem.Type,
                            forPrimaryKey: lookup["uid"] as! String)
                        return x as? T
                    }
                }
                
                return nil
            }
            
            return x[propName] as? T
        }
        set(newValue) {
            var x = self.asDict()
            
            if let newValue = newValue as? DataItem {
                x[propName] = ["type": newValue.genericType, "uid": newValue.uid]
            }
            else {
                x[propName] = newValue
            }
            
            do { try globalInMemoryObjectCache.set(uid, x) }
            catch { /* TODO ERROR HANDLIGNN */ }
            
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
    
    public func asDict() -> [String:Any] {
        var x:[String:Any]?
        do { x = try InMemoryObjectCache.get(uid) as? [String:Any] } catch { return [:] } // TODO refactor: handle error
        do { if x == nil { x = try transformToDict() } } catch { return [:] } // TODO refactor: handle error
        return x ?? [:]
    }
    
    convenience init(_ dict:[String:Any]) {
        self.init()
        
        do { try InMemoryObjectCache.set(self.uid, dict) }
        catch {
            // TODO Refactor error reporting
        }
    }
}
public typealias ViewArguments = UserState
