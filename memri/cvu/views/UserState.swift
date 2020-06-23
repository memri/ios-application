//
//  UserState.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

public class UserState: Object, CVUToString {
    @objc dynamic var memriID: String = DataItem.generateUUID()
    @objc dynamic var state:String = ""
    
    var onFirstSave: ((UserState) -> Void)? = nil
    
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
    
    func get<T>(_ propName:String) -> T? {
        let dict = self.asDict()
        
        if let lookup = dict[propName] as? [String:Any?], lookup["memriID"] != nil {
            let x:DataItem? = getDataItem(lookup["type"] as? String ?? "",
                                          lookup["memriID"] as? String ?? "")
            return x as? T
        }
        else if dict[propName] == nil {
            return nil
        }
        
        return dict[propName] as? T
    }
    
    func set<T>(_ propName:String, _ newValue:T?, persist:Bool = true) {
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
        
        if persist { scheduleWrite() }
    }
    
    private func transformToDict() throws -> [String:Any]{
        if state == "" { return [String:Any]() }
        let stored:[String:AnyCodable] = try unserialize(state) ?? [:]
        var dict = [String:Any]()
        
        for (key, value) in stored {
            dict[key] = value.value
        }
        
        try InMemoryObjectCache.set(self.memriID, dict)
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
        
        if let x = InMemoryObjectCache.get(memriID) as? [String : Any?] {
            realmWriteIfAvailable(self.realm) {
                do {
                    var values:[String:AnyCodable?] = [:]
                    
                    for (key, value) in x {
                        if let value = value as? AnyCodable {
                            values[key] = value
                        }
                        else {
                            values[key] = AnyCodable(value)
                        }
                    }
                    
                    let data = try MemriJSONEncoder.encode(values)
                    self["state"] = String(data: data, encoding: .utf8) ?? ""
                }
                catch let error {
                    debugHistory.error("Could not persist state object: \(error)")
                }
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
    
    public func merge(_ state:UserState) throws {
        let dict = asDict().merging(state.asDict(), uniquingKeysWith: { current, new in new })
        try InMemoryObjectCache.set(self.memriID, dict as [String:Any])
    }
    
    public func clone() -> UserState {
        UserState(asDict())
    }
    
    func toCVUString(_ depth: Int, _ tab: String) -> String {
        CVUSerializer.dictToString(asDict(), depth, tab)
    }
}
public typealias ViewArguments = UserState
