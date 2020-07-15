////
////  SessionView.swift
////  memri
////
////  Created by Koen van der Veen on 29/04/2020.
////  Copyright © 2020 memri. All rights reserved.
////
//
//import Combine
//import Foundation
//import RealmSwift
//import SwiftUI
//
//
//final class SessionView {
//    var uid: Int
//    var parsed: CVUParsedSessionDefinition
//    
//	public class func fromCVUDefinition(parsed: CVUParsedViewDefinition? = nil,
//										stored: CVUStoredDefinition? = nil,
//										viewArguments: ViewArguments? = nil,
//										userState: UserState? = nil,
//										datasource: Datasource? = nil) throws -> SessionView {
//		if parsed == nil, stored == nil {
//			throw "Missing CVU definition"
//		}
//
//		var ds: Datasource? = datasource
//		var us: UserState? = userState
//		var args: ViewArguments? = viewArguments
//
//		if ds == nil, let src = parsed?["datasourceDefinition"] as? CVUParsedDatasourceDefinition {
//			ds = try Datasource.fromCVUDefinition(src, viewArguments)
//		}
//		if userState == nil {
//			us = try UserState.clone(parsed?["userState"] as? UserState)
//		}
//		if viewArguments == nil {
//			args = try ViewArguments.clone(parsed?["viewArguments"] as? ViewArguments)
//		}
//
//		let view = try Cache.createItem(SessionView.self, values: [
//			"selector": parsed?.selector ?? stored?.selector ?? "[view]",
//			"name": parsed?["name"] as? String ?? stored?.name ?? "",
//		])
//
//		var toStore = stored
//		if stored == nil {
//			toStore = try Cache.createItem(CVUStoredDefinition.self, values: [
//				"type": "view",
//				"selector": parsed?.selector,
//				"domain": parsed?.domain,
//				"definition": parsed?.toCVUString(0, "    "),
//			])
//		}
//		if let toStore = toStore { view.set("viewDefinition", toStore) }
//		if let args = args { view.set("viewArguments", args) }
//		if let us = us { view.set("userState", us) }
//		if let ds = ds { view.set("datasource", ds) }
//
//		return view
//	}
//}
