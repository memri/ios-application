//
//  HTMLHelper.swift
//  EmailPlayground
//
//  Created by Toby Brennan on 21/7/20.
//

import Foundation
import SwiftSoup

class HTMLHelper {
	/// This function takes a HTML string and returns the plain text content
	static func getPlainText(html: String) -> String {
		do {
			return try SwiftSoup.parse(html).text()
		} catch {
			// LOG ERROR
			return ""
		}
	}
	
	/// This function takes a HTML string and returns an NSAttributedString maintaining only basic formatting
	/// This MUST be run on the *main thread *
	static func getSimpleAttributedString(html: String) -> NSAttributedString {
		do {
			guard let attribHTML = try SwiftSoup.clean(html, Whitelist.simpleText()),
				  let data = attribHTML.data(using: .utf8)
			else {
				// Invalid HTML, even after generous parsing
				return NSAttributedString()
			}
			let attribString = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
			return attribString
		} catch {
			// LOG ERROR
			return NSAttributedString()
		}
	}
	
	/// This function validates HTML and returns a NSAttributedString
	/// This MUST be run on the *main thread *
	static func getAttributedString(html: String) -> NSAttributedString? {
		do {
			guard let cleanHTML = cleanHTMLBasic(html),
				  let data = cleanHTML.data(using: .utf8)
			else {
				// Invalid HTML, even after generous parsing
				return NSAttributedString()
			}
			let attribString = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
			return attribString
		} catch {
			// LOG ERROR
			return nil
		}
	}
	
	/// This function validates HTML and returns a valid HTML string
	/// Maintains a limited set of elements
	static func cleanHTMLBasic(_ html: String) -> String? {
		do {
			return try SwiftSoup.clean(html, Whitelist.basic())
		} catch {
			// LOG ERROR
			return nil
		}
	}
	
	/// This function validates HTML and returns a valid HTML string
	/// Maintains structural elements (eg. div)
	static func cleanHTMLMaintainingStructuralElements(_ html: String) -> String? {
		do {
			return try SwiftSoup.clean(html, Whitelist.relaxed())
		} catch {
			// LOG ERROR
			return nil
		}
	}
	
}
