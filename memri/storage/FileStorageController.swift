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
        let split = uuid.split(separator: ".")
        let fileExt = split.count > 1 ? String(split.last ?? "jpg") : "jpg"
        if let fileName = split.first, let url = Bundle.main.url(forResource: "demoAssets/\(fileName)", withExtension: fileExt) {
            return url
        }
        // End hack

        return getFileStorageURL().appendingPathComponent(uuid, isDirectory: false)
    }

    static func exists(withUUID uuid: String) -> Bool {
        let fileURL = getURLForFile(withUUID: uuid)
        return FileManager.default.fileExists(atPath: fileURL.path)
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

    static func getDownsampledImage(
        fromFileForUUID uuid: String,
        maxDimension: CGFloat
    ) -> UIImage? {
        let fileURL = getURLForFile(withUUID: uuid)
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, sourceOptions)
        else { return nil }
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ] as CFDictionary

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            downsampleOptions
        ) else { return nil }

        return UIImage(cgImage: downsampledImage)
    }

    // Requires `ZipFoundation` package
//    static func unzipFile(from sourceURL: URL, to folder: String? = nil, progress: Progress? = nil) throws {
//        try FileManager().unzipItem(at: sourceURL, to: folder.map { getFileStorageURL().appendingPathComponent($0, isDirectory: true) } ?? getFileStorageURL(), progress: progress)
//    }
    static func deleteFolder(named folderName: String) throws {
        try FileManager.default
            .removeItem(at: getFileStorageURL()
                .appendingPathComponent(folderName, isDirectory: true))
    }

    static func deleteFile(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}
