//
//  IndexerAPI.swift
//  memri
//
//  Created by Koen van der Veen on 24/06/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation


public class IndexerAPI{
    
    public var context: MemriContext? = nil
    
    public func execute(_ indexerInstance: IndexerInstance, _ items: [DataItem]){
        if indexerInstance.name == "Note Label Indexer" {
            guard let notes = items as? [Note] else {
                print("Could not execute IndexerInstance \(indexerInstance) non note objects passed")
                    return
            }
            executeNoteLabelIndexer(indexerInstance, notes)
        }
        else {
            print("\n***COULD NOT FIND LOCAL INDEXER IN INDEXERAPI***\n")
        }
        
    }
}

extension IndexerAPI{
    public func executeNoteLabelIndexer(_ indexerInstance: IndexerInstance, _ items: [Note]){
        
        self.context?.cache.query(Datasource(query: "Label")) { error, labels in
            guard let labels = labels else {
                print("Abborting, no labels found: \(error)")
                return
            }
            
            for (i, label) in labels.enumerated() {
                let progress: Int = Int(((i+1) / labels.count) * 100)
                indexerInstance.set("progress", progress)
                let name: String? = label.get("name")
                let aliases: [String] = label.get("aliases") ?? []
                let allAliases: [String] = aliases + (name != nil ? [name!] : []).map { $0.lowercased() }
                
                for note in items {
                    let content_:String? = note.get("content")
                    guard let content = content_ else { continue }
                    
                    let contentString = content.removeHTML().lowercased()
                    
                    if allAliases.contains(where: contentString.contains) {
                        // If any of the aliases matches
                        do {
                            print("Adding label from \(note) to \(label)")
                            try label.addEdge("appliesTo", note)
                        }
                        catch {
                            print("Could not create edge")
                        }
                    }
                }
            }
        }
    }
}
