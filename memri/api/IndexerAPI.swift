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
            executeListIndexer(indexerInstance, notes)
        }
        
    }
}

extension IndexerAPI{
    public func executeListIndexer(_ indexerInstance: IndexerInstance, _ items: [Note]){
        
        for note in items {
            let content_:String? = note.get("content")
            
            guard let content = content_ else {
                continue
            }
            
            let contentString = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            
            // How to get the labels?
        }
        
        
    }
}
