//
// IndexerAPI.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation

public class IndexerAPI {
    public var context: MemriContext?

    public func execute(_ indexerInstance: IndexerRun, _ items: [Item]) throws {
        if indexerInstance.name == "Note Label Indexer" {
            guard let notes = items as? [Note] else {
                throw "Could not execute IndexerRun \(indexerInstance) non note objects passed"
            }
            try executeNoteLabelIndexer(indexerInstance, notes)
        }
        else {
            throw "\n***COULD NOT FIND LOCAL INDEXER IN INDEXERAPI***\n"
        }
    }
}

public extension IndexerAPI {
    func executeNoteLabelIndexer(_ indexerInstance: IndexerRun, _ items: [Note]) throws {
        try context?.cache.query(Datasource(query: "Label")) { error, labels in
            guard let labels = labels else {
                if let error = error {
                    print("Aborting, no labels found: \(error)")
                }
                return
            }

            for (i, label) in labels.enumerated() {
                let progress = Int(((i + 1) / labels.count) * 100)
                indexerInstance.set("progress", progress)
                let name: String? = label.get("name")
                let aliases: [String] = label.get("aliases") ?? []
                let allAliases: [String] = aliases + (name != nil ? [name!] : [])
                    .map { $0.lowercased() }

                for note in items {
                    let content_: String? = note.get("content")
                    guard let content = content_ else { continue }

                    let contentString = content.strippingHTMLtags().lowercased()

                    if allAliases.contains(where: contentString.contains) {
                        // If any of the aliases matches
                        do {
                            print("Adding label from \(note) to \(label)")
                            _ = try label.link(note, type: "appliesTo")
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
