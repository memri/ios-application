//
// FileStorageController.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import UIKit

class FileStorageController {
    private init() {}

    /// Gets the base URL for storing files
    /// - Returns: the computed database file path
    static func getFileStorageURL() -> URL {
        // Inline functions
        func createIfDoesntExist(directoryURL: URL) {
            do {
                try FileManager.default.createDirectory(
                    at: directoryURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
            catch {
                print(error)
            }
        }

        #if targetEnvironment(simulator)
            // On simulator, use a local folder for easy inspection
            guard let homeDir = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"]
            else { fatalError("Couldn't find home directory from simulator environment") }
            let memriFileURL = URL(fileURLWithPath: homeDir, isDirectory: true)
                .appendingPathComponent(
                    "memriDevData/fileStore",
                    isDirectory: true
                )
            createIfDoesntExist(directoryURL: memriFileURL)
            return memriFileURL
        #else
            // On device, store under documents
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentsDirectory = paths[0]
            let memriFileURL = documentsDirectory.appendingPathComponent(
                "fileStore",
                isDirectory: true
            )
            createIfDoesntExist(directoryURL: memriFileURL)
            return memriFileURL
        #endif
    }

    static func getURLForFile(withUUID uuid: String) -> URL {
        // Little hack to make our demo data work
        if let url = Bundle.main.url(forResource: "DemoAssets/\(uuid)", withExtension: "jpg") {
            return url
        }

        return getFileStorageURL().appendingPathComponent(uuid, isDirectory: false)
    }

    static func getData(fromFileForUUID uuid: String) -> Data? {
        let fileURL = getURLForFile(withUUID: uuid)
        return try? Data(contentsOf: fileURL)
    }

    static func writeData(_ data: Data, toFileForUUID uuid: String) throws {
        let fileURL = getURLForFile(withUUID: uuid)
        try data.write(to: fileURL, options: .atomicWrite)
    }

    static func deleteFile(withUUID uuid: String) throws {
        let fileURL = getURLForFile(withUUID: uuid)
        try FileManager.default.removeItem(at: fileURL)
    }

    static func getImage(fromFileForUUID uuid: String) -> UIImage? {
        let fileURL = getURLForFile(withUUID: uuid)
        return UIImage(contentsOfFile: fileURL.path)
    }
}
