//
//  Installer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

public class Installer {
	private var realm: Realm

	init(_ rlm: Realm) {
		realm = rlm
	}

	public func install(_: MemriContext) {}

	public func installIfNeeded(_ context: MemriContext, _ callback: () throws -> Void) throws {
		let installLogs = realm.objects(AuditItem.self).filter("action = 'install'")

		// TODO: Refactor: check version??
		if installLogs.count == 0 {
			print("Installing defaults in the database")

			// Load default navigation items in database
			context.navigation.install()

			// Load default objects in database
			context.cache.install()

			// Load default settings in database
			context.settings.install()

			// Load default views in database
			context.views.context = context
			try context.views.install()

			// Load default sessions in database
			try context.sessions.install(context)

			// Installation complete
			try realm.write {
				realm.create(AuditItem.self, value: [
					"action": "install",
					"date": Date(),
					"contents": try serialize(["version": "1.0"]),
				])
			}
		}

		try callback()
	}
}
