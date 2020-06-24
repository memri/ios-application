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
        if indexerInstance.name == "Lists indexer" {
            executeListIndexer(indexerInstance)
        }
        
    }
}

extension IndexerAPI{
    public func executeListIndexer(_ indexerInstance: IndexerInstance){
        // TODO: Implement
        
    }
}
