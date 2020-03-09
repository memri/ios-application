//
//  ViewTest.swift
//  memri
//
//  Created by Koen van der Veen on 26/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import XCTest
@testable import memri


//class Test2: Codable {
//
//    public var name2: String = "test2 default name"
//    public var styles2: [String] = []
//
//    convenience required init(from decoder: Decoder) throws {
//        self.init()
//        name2   = try decoder.decodeIfPresent("name2") ?? name2
//        styles2 = try decoder.decodeIfPresent("styles") ?? styles2
//           
//    }
//}
//
//class Test: Codable {
//
//    public var name: String = "default name"
//    public var styles: [String] = []
//    public var test2: Test2 = Test2()
//
//    convenience required init(from decoder: Decoder) throws {
//        self.init()
//        try decodeFromTuples(decoder,
//                             [(name, "name"),(styles, "styles"),(test2, "test2")] as [(Any, String)])
//    }
//}


class ViewTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoadSessionViewFromJson() {
        let sessionView =  try! SessionView.from_json("empty_sessionview")
    }
    
//    func testLoadtest() {
//        let decoder = JSONDecoder()
//
//        let refWithName = "{\"styles\": [\"Randy\"], \"test2\": { \"name2\": \"tering nice dat het werkt\" } }"
//        let b = try! decoder.decode(Test.self, from: refWithName.data(using: .utf8)!)
//        
//        
//        print(b.name)
//        print(b.styles)
//        print(b.test2.name2)
////        let test =  try! Test.from_json("test")
//        
////        let test2 = Test(name: "",title:"")
//    }


    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
