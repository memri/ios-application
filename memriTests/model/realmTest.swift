//
//  realmTest.swift
//  memriTests
//
//  Created by Koen van der Veen on 30/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import XCTest
@testable import memri
import RealmSwift

class realmTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRealmCreate() {
        #if targetEnvironment(simulator)
            config.fileURL = URL(string: "file://\(try! getRealmPath())/memri.realm")
        #endif
        
        Realm.Configuration.defaultConfiguration = config
        let realm = try! Realm()
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
