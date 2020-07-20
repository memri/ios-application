//
//  ViewDebugger.swift
//  memri
//
//  Created by Ruben Daniels on 5/12/20.
//  Copyright © 2020 memri. All rights reserved.
//

import ASCollectionView
import Foundation

// TODO: file watcher
// let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
// let watcher = DirectoryWatcher.watch(documentsUrl)
//
// watcher.onNewFiles = { newFiles in
//  // Files have been added
// }
//
// watcher.onDeletedFiles = { deletedFiles in
//  // Files have been deleted
// }
// Call watcher.stopWatching() and watcher.startWatching() to pause / resume.

/*
 Needs to know, which views are currently displayed (in the cascade)
 Then updates the view by recomputing the view with the new values
 Display any errors in the console
 */

import Combine
import SwiftUI

enum InfoType: String {
	case info, warn, error

	var icon: String {
		switch self {
		case .info: return "info.circle.fill"
		case .warn: return "exclamationmark.triangle.fill"
		case .error: return "xmark.octagon.fill"
		}
	}

	var color: Color {
		switch self {
		case .info: return Color.gray
		case .warn: return Color.yellow
		case .error: return Color.red
		}
	}
}

class InfoState: Hashable {
	var id = UUID()

	static func == (lhs: InfoState, rhs: InfoState) -> Bool {
		lhs.id == rhs.id
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(displayMessage)
		hasher.combine(date)
	}

	var date: Date = Date()
	var displayMessage: String = ""
	var messageCount: Int = 1
	var type: InfoType = .info
	//    var cascadableView: ComputedView

	init(displayMessage m: String) {
		displayMessage = m
	}
}

class ErrorState: InfoState {
	var error: Error?

	override init(displayMessage m: String) {
		super.init(displayMessage: m)

		type = .error
	}
}

class WarnState: InfoState {
	override init(displayMessage m: String) {
		super.init(displayMessage: m)

		type = .warn
	}
}

class DebugHistory: ObservableObject {
	@Published var showErrorConsole: Bool = false

	var log = [InfoState]()

	private func time() -> String {
		let d = Date()

		let dateFormatter = DateFormatter()

		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
		dateFormatter.locale = Locale(identifier: "en_US")
		dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

		return "[\(dateFormatter.string(from: d))]"
	}

	func info(_ message: String /* , _ cascadableView:ComputedView */ ) {
		// if same view
		if log.last?.displayMessage == message {
			log[log.count - 1].messageCount += 1
		} else {
			log.append(InfoState(
				displayMessage: message
				//            cascadableView: cascadableView
			))
		}

		print("\(time()) INFO: \(message.replace("\n", "\n    "))")
	}

	func warn(_ message: String /* , _ cascadableView:ComputedView */ ) {
		// if same view
		if log.last?.displayMessage == message {
			log[log.count - 1].messageCount += 1
		} else {
			log.append(WarnState(
				displayMessage: message
				//            cascadableView: cascadableView
			))
		}

		print("\(time()) WARNING: \(message.replace("\n", "\n    "))")
	}

	func error(_ message: String /* , _ cascadableView:ComputedView */ ) {
		// if same view
		if log.last?.displayMessage == message {
			log[log.count - 1].messageCount += 1
		} else {
			log.append(ErrorState(
				displayMessage: message
				//            cascadableView: cascadableView
			))
		}

		if Settings.shared.get("device/debug/autoShowErrorConsole") ?? false {
			showErrorConsole = true
		}

		print("\(time()) ERROR: \(message.replace("\n", "\n    "))")
	}

	func clear() {
		log = []

		objectWillChange.send()
	}
}

// Intentionally global
var debugHistory = DebugHistory()

struct DebugConsole: View {
	@EnvironmentObject var context: MemriContext

	@ObservedObject var history = debugHistory

	@State var scrollPosition: ASTableViewScrollPosition?

	var body: some View {
		let dateFormatter = DateFormatter()

		dateFormatter.dateFormat = "h:mm a"
		dateFormatter.locale = Locale(identifier: "en_US")
		//        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

		return Group {
			if debugHistory.showErrorConsole {
				VStack(spacing: 0) {
					HStack {
						Text("Console")
							.font(.system(size: 14, weight: .semibold))
							.padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
							.foregroundColor(Color(hex: "555"))
                        Spacer()
						Button(action: { self.scrollPosition = .top }) {
							Text("scroll to top")
						}
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#999"))
                        .padding(10)
						Button(action: { self.history.clear() }) {
							Text("clear")
						}
						.font(.system(size: 14, weight: .semibold))
						.foregroundColor(Color(hex: "#999"))
						.padding(10)
						Button(action: {
							self.history.showErrorConsole = false
                        }) {
							Image(systemName: "xmark")
						}
						.font(.system(size: 12))
						.foregroundColor(Color(hex: "#999"))
						.padding(10)
					}
					.fullWidth()
					.background(Color(hex: "#eee"))

					ASTableView(section:
						ASSection(id: 0, data: debugHistory.log.reversed(), dataID: \.self) { notice, _ in
							HStack(alignment: .top, spacing: 4) {
								Image(systemName: notice.type.icon)
									.padding(.top, 4)
									.font(.system(size: 14))
									.foregroundColor(notice.type.color)

								Text(notice.displayMessage)
									.multilineTextAlignment(.leading)
									.fixedSize(horizontal: false, vertical: true)
									.font(.system(size: 14))
									.padding(.top, 1)
									.foregroundColor(Color(hex: "#333"))

								if notice.messageCount > 1 {
									Text("\(notice.messageCount)x")
										.padding(3)
										.background(Color.yellow)
										.cornerRadius(20)
										.font(.system(size: 12, weight: .semibold))
										.foregroundColor(Color.white)
								}

								Spacer()

								Text(dateFormatter.string(from: notice.date))
									.font(.system(size: 12))
									.padding(.top, 1)
									.foregroundColor(Color(hex: "#999"))
							}
							.padding(.horizontal)
							.padding(.vertical, 4)
							.fullWidth()
                    })
						.scrollPositionSetter($scrollPosition)
				}
				.frame(maxWidth: .infinity, alignment: .topLeading)
				.background(Color.white.edgesIgnoringSafeArea(.all))
				.border(width: [1, 0, 0, 0], color: Color(hex: "ddd"))
				.frame(height: 200)
			}
		}
	}
}

struct ErrorConsole_Previews: PreviewProvider {
	static var previews: some View {
		DebugConsole().environmentObject(try! RootContext(name: "", key: "").mockBoot())
	}
}
