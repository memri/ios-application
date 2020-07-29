//
// ItemTest.swift
// Copyright © 2020 memri. All rights reserved.

@testable import memri
import RealmSwift
import XCTest

class ItemTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDeserializeItem() throws {
        let str = """
        [{
            "_type": "Note",
            "uid": \(try Cache.incrementUID()),
            "starred": true,
            "dateCreated": 1586517071000,
            "version": 10
        }]
        """
        guard let item = try Item.fromJSONString(str).first else {
            throw "Unable to create item"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        XCTAssertEqual(item.get("starred"), true)
        XCTAssertEqual(
            item.get("dateCreated", type: Date.self)?.timeIntervalSince1970,
            1_586_517_071
        )
        XCTAssertEqual(item.get("version"), 10)
    }

    func testGetString() throws {
        let str = """
        [{
            "_type": "Note",
            "uid": \(try Cache.incrementUID()),
            "starred": true,
            "dateCreated": 1586517071000,
            "version": 10
        }]
        """
        guard let item = try Item.fromJSONString(str).first else {
            throw "Unable to create item"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        XCTAssertEqual(item.getString("starred"), "true")
        XCTAssertEqual(item.getString("dateCreated"), "2020/04/10 13:11")
        XCTAssertEqual(item.getString("version"), "10")
    }

    func testGetType() throws {
        let note = Note()
        let n = note.getType()!
        XCTAssertEqual("\(n)", "Note")
    }

    func testSet() throws {
        let item = Item()
        XCTAssertEqual(item.version, 0)
        item.set("version", 1)
        XCTAssertEqual(item.version, 1)
    }

    func testToggle() throws {
        let item = Item()
        XCTAssertEqual(item.starred, false)
        try item.toggle("starred")
        XCTAssertEqual(item.starred, true)
    }

    func testMerge() throws {
        let data1 = Data("""
        {
            "memriID": "0x012345",
            "starred": true,
            "dateCreated": "2020-04-10T11:11:11Z",
            "version": 10
        }
        """.utf8)
        let item1: Item = try MemriJSONDecoder.decode(Item.self, from: data1)

        let data2 = Data("""
        {
            "memriID": "333",
            "starred": false
        }
        """.utf8)
        let item2: Item = try MemriJSONDecoder.decode(Item.self, from: data2)

        item1.merge(item2)

        XCTAssertEqual(item1.get("memriID"), "333")
        XCTAssertEqual(item1.get("starred"), false)
        XCTAssertEqual(
            item1.get("dateCreated", type: Date.self)!.timeIntervalSince1970,
            1_586_517_071
        )
        XCTAssertEqual(item1.get("version"), 10)
    }

    func testSafeMergeVersion() throws {
        let data1 = Data("""
        {
            "memriID": "0x012345",
            "starred": true,
            "dateCreated": "2020-04-10T11:11:11Z",
            "version": 10
        }
        """.utf8)
        let item1: Item = try MemriJSONDecoder.decode(Item.self, from: data1)

        let data2 = Data("""
        {
            "memriID": "333",
            "starred": false,
            "version": 11
        }
        """.utf8)
        let item2: Item = try MemriJSONDecoder.decode(Item.self, from: data2)

        XCTAssertEqual(item1.safeMerge(item1), false)
        XCTAssertEqual(item2.safeMerge(item1), false)
        XCTAssertEqual(item1.safeMerge(item2), true)
    }

    func testSafeMergeUpdateFields() throws {
        let data1 = Data("""
        {
            "memriID": "0x012345",
            "starred": true,
            "dateCreated": "2020-04-10T11:11:11Z",
            "version": 10
        }
        """.utf8)
        let item1: Item = try MemriJSONDecoder.decode(Item.self, from: data1)

        let data2 = Data("""
        {
            "memriID": "333",
            "starred": false,
            "version": 11
        }
        """.utf8)
        let item2: Item = try MemriJSONDecoder.decode(Item.self, from: data2)

        item1._updated.append("starred")

        XCTAssertEqual(item1.safeMerge(item2), false)
    }

    func testAccess() throws {
        let item1 = try Cache.createItem(Note.self, values: [
            "uid": "0x012345",
            "starred": true,
            "dateCreated": "2020-04-10T11:11:11Z",
            "version": 10
        ])

        let dt = item1.dateAccessed
        item1.accessed()
        XCTAssertNotEqual(dt, item1.dateAccessed)
    }

    func testLinkAndUnlink() throws {
        let data1 = Data("""
        {
            "memriID": "0x012345",
            "starred": true,
            "dateCreated": "2020-04-10T11:11:11Z",
            "version": 10
        }
        """.utf8)
        let item1: Person = try MemriJSONDecoder.decode(Person.self, from: data1)

        let data2 = Data("""
        {
            "memriID": "0x012346",
            "starred": true,
            "dateCreated": "2020-04-10T11:11:11Z",
            "version":9
        }
        """.utf8)
        let item2: Person = try MemriJSONDecoder.decode(Person.self, from: data2)

        do {
            _ = try item1.link(item2, type: "relationship")
            XCTAssertEqual(item2.relationship?.first, item2)

            _ = try item1.unlink(item2, type: "relationship")
            XCTAssertNotEqual(item2.relationship?.first, item2)
        }
        catch {
            XCTFail("\(error)")
        }
    }

    func createDataset() throws -> Person {
        let data1 = Data("""
        [
        {
            "memriID": "1",
            "starred": true,
            "dateCreated": "2020-04-10T11:11:11Z",
            "version": 10,
            "firstName": "Abhi"
        },
        {
            "memriID": "2",
            "starred": true,
            "dateCreated": "2020-04-10T11:11:11Z",
            "version": 10,
            "firstName": "Bernie"
        },
        {
            "memriID": "3",
            "starred": true,
            "dateCreated": "2020-04-10T11:11:11Z",
            "version": 10,
            "firstName": "Coolio"
        },
        {
            "memriID": "4",
            "starred": true,
            "dateCreated": "2020-04-10T11:11:11Z",
            "version": 10,
            "firstName": "Dufus"
        },
        {
            "memriID": "5",
            "starred": true,
            "dateCreated": "2020-04-10T11:11:11Z",
            "version": 10,
            "firstName": "Edward"
        },
        {
            "memriID": "6",
            "starred": true,
            "dateCreated": "2020-04-10T11:11:11Z",
            "version": 10,
            "firstName": "Fiona"
        }
        ]
        """.utf8)
        let items: [Person] = try MemriJSONDecoder.decode([Person].self, from: data1)

        DatabaseController.current(write:true) { realm in
            for item in items {
                realm.add(item, update: .modified)
            }
        }

        do {
            _ = try items[0].link(items[1], type: "brother")
            _ = try items[0].link(items[2], type: "father")
            _ = try items[0].link(items[3], type: "sister")
            _ = try items[1].link(items[3], type: "aunt")
            _ = try items[1].link(items[4], type: "family")
            _ = try items[2].link(items[1], type: "cousin")
            _ = try items[2].link(items[5], type: "mother")
        }
        catch {
            XCTFail("\(error)")
        }

        return items[0]
    }

    func testEdgesSingle() throws {
        let person = try createDataset()
        XCTAssertEqual(person.edge("father")?.item(type: Person.self)?.firstName, "Coolio")
    }

    func testEdgesSingleExpanded() throws {
        let person = try createDataset()
        XCTAssertEqual(person.edge("family")?.item(type: Person.self)?.firstName, "Bernie")
    }

    func testEdgesMulti() throws {
        let person = try createDataset()
        XCTAssertEqual(
            person.edge(["sister", "father"])?.item(type: Person.self)?.firstName,
            "Coolio"
        )
    }

    func testEdgesMultiExpanded() throws {
        let person = try createDataset()
        XCTAssertEqual(
            person.edge(["aunt", "family"])?.item(type: Person.self)?.firstName,
            "Bernie"
        )
    }

    func testEdgeSingle() throws {
        let person = try createDataset()
        XCTAssertEqual(person.edges("father")?.items()?.count, 1)
    }

    func testEdgeSingleExpanded() throws {
        let person = try createDataset()
        XCTAssertEqual(person.edges("family")?.items()?.count, 3)
    }

    func testEdgeMulti() throws {
        let person = try createDataset()
        XCTAssertEqual(person.edge("brother")?.item()?.edges(["sister", "aunt"])?.items()?.count, 1)
        XCTAssertEqual(person.edge("father")?.item()?.edges(["sister", "aunt"])?.items()?.count, 0)
    }

    func testEdgeMultiExpanded() throws {
        let person = try createDataset()
        XCTAssertEqual(person.edge("brother")?.item()?.edges(["aunt", "family"])?.items()?.count, 2)
        XCTAssertEqual(person.edge("father")?.item()?.edges(["aunt", "family"])?.items()?.count, 2)
    }

    //    func testPerformanceExample() throws {
    //        // This is an example of a performance test case.
    //        self.measure {
    //            // Put the code you want to measure the time of here.
    //        }
    //    }
}
