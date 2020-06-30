//
//  SessionView.swift
//  memri
//
//  Created by Koen van der Veen on 29/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import Foundation
import RealmSwift
import SwiftUI

extension SessionView {
	override var computedTitle: String {
		if let value = name { return value }
		//        else if let rendererName = self.rendererName {
		//            return "A \(rendererName) showing: \(self.datasource?.query ?? "")"
		//        }
		else if let query = datasource?.query {
			return "Showing: \(query)"
		}
		return "[No Name]"
	}

	func mergeState(_ view: SessionView) throws {
		realmWriteIfAvailable(realm) {
			if let us = view.userState {
				if userState == nil { userState = UserState() }
				try userState?.merge(us)
			}
			if let args = view.viewArguments {
				if viewArguments == nil { viewArguments = ViewArguments() }
				try viewArguments?.merge(args)
			}
		}
	}

	public class func fromCVUDefinition(parsed: CVUParsedViewDefinition? = nil,
										stored: CVUStoredDefinition? = nil,
										viewArguments: ViewArguments? = nil,
										userState: UserState? = nil,
										datasource: Datasource? = nil) throws -> SessionView {
		if parsed == nil, stored == nil {
			throw "Missing CVU definition"
		}

		var ds: Datasource? = datasource
		var us: UserState? = userState
		var args: ViewArguments? = viewArguments

		if ds == nil, let src = parsed?["datasourceDefinition"] as? CVUParsedDatasourceDefinition {
			ds = try Datasource.fromCVUDefinition(src, viewArguments)
		}
		if userState == nil { us = (parsed?["userState"] as? UserState)?.clone() }
		if viewArguments == nil { args = (parsed?["viewArguments"] as? ViewArguments)?.clone() }

		var values: [String: Any?] = [
			"selector": parsed?.selector ?? stored?.selector ?? "[view]",
			"name": parsed?["name"] as? String ?? stored?.name ?? "",
			"viewDefinition": stored ?? CVUStoredDefinition(value: [
				"type": "view",
				"selector": parsed?.selector,
				"domain": parsed?.domain,
				"definition": parsed?.toCVUString(0, "    "),
			]),
		]

		if let args = args { values["viewArguments"] = args }
		if let us = us { values["userState"] = us }
		if let ds = ds { values["datasource"] = ds }

		return SessionView(value: values)
	}
}
