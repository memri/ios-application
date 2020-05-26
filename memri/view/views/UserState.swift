//
//  UserState.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

public class UserState: Object {
    @objc dynamic var memriID: String = DataItem.generateUUID()
    @objc dynamic var state:String = ""
    
    var onFirstSave: ((UserState) -> Void)? = nil
    
    func get<T>(_ propName:String) -> T? {
        let x = self.asDict()
        
        if T.self == DataItem.self {
            if let lookup = x[propName] as? [String:Any] {
                if let type = DataItemFamily(rawValue: lookup["type"] as? String ?? "") {
                    let x:DataItem? = realm?.object(
                        ofType: DataItemFamily.getType(type)() as! DataItem.Type,
                        forPrimaryKey: lookup["memriID"] as? String ?? "")
                    return x as? T
                }
            }
            
            return nil
        }
        
        return x[propName] as? T
    }
    
    func set<T>(_ propName:String, _ newValue:T) {
        if let event = onFirstSave {
            event(self)
            onFirstSave = nil
        }
        
        var x = self.asDict()
        
        if let newValue = newValue as? DataItem {
            x[propName] = ["type": newValue.genericType, "memriID": newValue.memriID]
        }
        else {
            x[propName] = newValue
        }
        
        do { try globalInMemoryObjectCache.set(memriID, x) }
        catch { /* TODO ERROR HANDLIGNN */ }
        
        scheduleWrite()
    }
    
    private func transformToDict() throws -> [String:Any]{
        if state == "" { return [String:Any]() }
        let dict:[String:AnyDecodable] = unserialize(state) ?? [:]
        try InMemoryObjectCache.set(self.memriID, dict as [String:Any])
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
        
        if let x = InMemoryObjectCache.get(memriID) as? [String : Any] {
            realmWriteIfAvailable(self.realm) {
                print(self.memriID)
                print(x)
                self["state"] = serialize(AnyCodable(x))
            }
        }
    }
    
    // Requires support for dataItem lookup.
    
    public func toggleState(_ stateName:String) {
        let x:Bool = self.get(stateName) ?? true
        self.set(stateName, !x)
    }

    public func hasState(_ stateName:String) -> Bool {
        let x:Bool = self.get(stateName) ?? false
        return x
    }
    
    public func asDict() -> [String:Any] {
        var x:[String:Any]?
        x = InMemoryObjectCache.get(memriID) as? [String:Any]
        do { if x == nil { x = try transformToDict() } } catch { return [:] } // TODO refactor: handle error
        return x ?? [:]
    }
    
    convenience init(_ dict:[String:Any]) {
        self.init()
        
        do { try InMemoryObjectCache.set(self.memriID, dict) }
        catch {
            // TODO Refactor error reporting
        }
    }
    
    convenience init(onFirstSave:@escaping (UserState) -> Void) {
        self.init()
        self.onFirstSave = onFirstSave
    }
}
public typealias ViewArguments = UserState
