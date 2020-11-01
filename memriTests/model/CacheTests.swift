//
// CacheTests.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import XCTest

class CacheTests: XCTestCase {
    var testCache = try! Cache(PodAPI())
    var installer = Installer()

    override func setUp() {
        // reset cache
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func getCountry(_ name: String) throws -> Country {
        let realm = try DatabaseController.getRealmSync()
        guard let country = realm.objects(Country.self).filter("name = '\(name)'").first else {
            throw "Could not find country to delete"
        }
        return country
    }

    func testCacheInstall() throws {
        installer.installForTesting { error, context in
            guard let _ = context else { throw "Failed to initialize: \(error!)" }

            let realm = try DatabaseController.getRealmSync()
            XCTAssertTrue(realm.objects(Country.self).count > 0)
        }
    }

    func testGetItem() throws {
        installer.installForTesting { error, context in
            guard let _ = context else { throw "Failed to initialize: \(error!)" }

            XCTAssertEqual(try self.getCountry("Aruba").getString("name"), "Aruba")
        }
    }

    func testEmptyQuery() throws {
        try testCache.query(Datasource(query: "")) { _, items in
            XCTAssertEqual(items, nil)
        }
    }

    func testTypeQuery() throws {
        installer.installForTesting { error, context in
            guard let _ = context else { throw "Failed to initialize: \(error!)" }

            let types = ["Person", "Note", "CVUStoredDefinition", "Address", "Country"]

            for itemType in types {
                try self.testCache
                    .query(Datasource(query: itemType), syncWithRemote: false) { _, items in
                        if let result = items {
                            XCTAssertTrue(result.allSatisfy { item in
                                item.genericType == itemType
                            })
                        }
                        else {
                            XCTFail()
                        }
                    }
            }
        }
    }

    func testFilteredQuery() {
        // TODO:
    }

    func testSortedQuery() {
        // TODO:
    }

    func testParseQuery() {
        let (type1, filter1) = testCache.parseQuery("note")
        XCTAssertTrue(type1 == "note"); XCTAssertTrue(filter1 == nil)

        let (type2, filter2) = testCache.parseQuery("* x<40")
        XCTAssertTrue(type2 == "*"); XCTAssertTrue(filter2 == "x<40")

        let (type3, filter3) = testCache.parseQuery("note x == 40")
        XCTAssertTrue(type3 == "note"); XCTAssertTrue(filter3 == "x == 40")
    }

    func testGetResultSet() throws {
        installer.installForTesting { error, context in
            guard let _ = context else { throw "Failed to initialize: \(error!)" }

            // TODO: not sure what this should test yet
            _ = self.testCache.getResultSet(Datasource(query: "*"))
        }
    }

//    func testAddToCache() throws {
//        let note = Note()
//        _ = try Cache.addToCache(note)
//        // TODO: what to test here
//    }

    func testAddToCacheConflicts() throws {
        installer.installForTesting { error, context in
            guard let _ = context else { throw "Failed to initialize: \(error!)" }

            let item = try Cache.createItem(Note.self, values: [
                "title": "hello world", "version": 1,
            ])

            guard let uid = item.uid.value else {
                throw "Could not store item"
            }

            let note = Note(value: ["uid": uid, "title": "changed", "version": 2])
            let cachedNote = try Cache.addToCache(note)

            XCTAssertEqual((cachedNote as? Note)?.title, "changed")

            let note2 = Note(value: ["uid": uid, "title": "error", "version": 2])
            let notUpdatedNote = try Cache.addToCache(note2)

            XCTAssertEqual((notUpdatedNote as? Note)?.title, "changed")

            DatabaseController.sync(write: true) { _ in
                notUpdatedNote._action = nil
            }

            item.set("title", "updated")

            let note3 = Note(value: ["uid": uid, "content": "no conflict", "version": 3])
            let storedItem = try Cache.addToCache(note3)

            XCTAssertEqual((storedItem as? Note)?.title, "updated")
            XCTAssertEqual((storedItem as? Note)?.content, "no conflict")
            XCTAssertEqual(storedItem.version, 3)

            let note4 = Note(value: ["uid": uid, "title": "conflict", "version": 4])
            XCTAssertThrowsError(_ = try Cache.addToCache(note4))
        }
    }

    func testDelete() throws {
        installer.installForTesting { error, context in
            guard let _ = context else { throw "Failed to initialize: \(error!)" }

            let item = try self.getCountry("Aruba")
            try self.testCache.delete(item)
            let item2 = try self.getCountry("Aruba")
            XCTAssertTrue(item2.deleted == true)
        }
    }

    func testDeleteMulti() throws {
        installer.installForTesting { error, context in
            guard let _ = context else { throw "Failed to initialize: \(error!)" }

            let items = [
                try self.getCountry("Aruba"),
                try self.getCountry("Antarctica"),
            ]

            try self.testCache.delete(items)

            let items2 = [
                try self.getCountry("Aruba"),
                try self.getCountry("Antarctica"),
            ]

            XCTAssertTrue(items2.allSatisfy { $0?.deleted == true || $0 == nil })
        }
    }

    func testDuplicate() throws {
        installer.installForTesting { error, context in
            guard let _ = context else { throw "Failed to initialize: \(error!)" }

            let item = try self.getCountry("Aruba")
            let copy = try self.testCache.duplicate(item)
            let cls = item.getType()

            for prop in item.objectSchema.properties {
                if prop.name != cls!.primaryKey() {
                    _ = item.isEqualProperty(prop.name, copy)
                }
            }
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
