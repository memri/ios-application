//
// NoteTest.swift
// Copyright © 2020 memri. All rights reserved.

import XCTest

class HTMLNoteTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let filePath = Bundle.main.url(forResource: "exampleNote2", withExtension: "html")
        let contents = try String(contentsOf: filePath!)

        let htmlData = NSString(string: contents).data(using: String.Encoding.unicode.rawValue)
        let options = [
            NSAttributedString.DocumentReadingOptionKey.documentType:
                NSAttributedString.DocumentType.html,
        ]
        let attributedString = try NSMutableAttributedString(data: htmlData ?? Data(),
                                                             options: options,
                                                             documentAttributes: nil)

        dump(attributedString)

        // read html as string
        //        let data = readFromPath("exampleNote.html")

        // conver to rtf
    }

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
}
