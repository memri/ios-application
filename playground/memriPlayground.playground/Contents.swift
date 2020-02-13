import UIKit
import Foundation


enum MemriError: Error {
    case basic
}

func wPrint( _ object: @escaping () -> Any){
    let when = DispatchTime.now() + 0.1
    DispatchQueue.main.asyncAfter(deadline: when) {
        print(object())
    }
}

// Create podAPI instance
let testPodAPI = PodAPI("mytestkey")
let sr = testPodAPI.query("get notes query")
wPrint({sr.data})


// Create Cache
let cache = Cache(testPodAPI)
let sr2 = cache.getByType(type: "note")
wPrint({sr2!.data})

let sr3 = cache.getByType(type: "note")
wPrint({sr3!.data})

// Initialize DataItems from json


//func serializeToDataItems(file: String, ext: String) -> [DataItem]{
//    let fileURL = Bundle.main.url(forResource: "test_dataItems", withExtension: "json")
//    let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
//    let jsonData = jsonString.data(using: .utf8)!
//    let items: [DataItem] = try! JSONDecoder().decode([DataItem].self, from: jsonData)
//    return items
//}

//let items = serializeToDataItems(file: "test_dataItems", ext: "json")

//let fileURL = Bundle.main.url(forResource: "test_dataItems", withExtension: "json")
//let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
//let jsonData = jsonString.data(using: .utf8)!
//let items: [DataItem] = try! JSONDecoder().decode([DataItem].self, from: jsonData)

//for item in items {
//    print(item.uid)
//    print(item.type)
//    print(item.predicates)
//    print(item.properties)
//    print()
//}
















