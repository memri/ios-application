import UIKit
import Foundation
import SwiftUI
import PlaygroundSupport


enum MemriError: Error {
    case basic
}

func wPrint( _ object: @escaping () -> Any){
    let when = DispatchTime.now() + 0.1
    DispatchQueue.main.asyncAfter(deadline: when) {
        print(object())
    }
}
/*
MODEL
*/

var x=[1,2,3,4]

print(x[0...1] + [8,9,10])

//Create podAPI instance

//let testPodAPI = PodAPI("mytestkey")
//let sr = testPodAPI.query("get notes query")
//wPrint({sr.data})


// Create Cache and query
//let cache = Cache(testPodAPI)
//let sr2 = cache.getByType(type: "note")
//wPrint({sr2!.data})
//
// # redo query, use cache
//let sr3 = cache.getByType(type: "note")
//wPrint({sr3!.data})
//
// # Initialize DataItems from json
//let items = DataItem.from_json(file: "test_dataItems")
//
//for item in items {
//    let props: [Any] = [item.uid, item.type, item.predicates, item.properties]
//    for prop in props{print(prop)}
//    print()
//}

//# Deserialzing a view from json
//let testView = MemriView.from_json("test_views")[0]


/*
# Deserializing a session from json, init a browser with it
*/

//let testSession = try Session.from_json("test_session")
//let testBrowser = Browser(testSession)
//
//
//print(testBrowser.currentSession.currentSessionView)
//
//
//PlaygroundPage.current.setLiveView(testBrowser)

// loads view from json, a view describes all UI elements
// loads session (list of views) from json
// init browser with session
// browser.setstate() : populates all the browserelements (topnav/renderer/etc/)
// get view

//browser

// session
// setstate(session):
//    current session op browserobject
//    call setstate op topnaviatation , renderer, search
//


// browser -> topnav -> items -> title
// set stuff in json from view
// show that on screen
















