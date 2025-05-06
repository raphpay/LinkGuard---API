//
//  Scan+FieldKeys.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent

extension Scan {
	enum V20250505 {
		static let schemaName = "scans"
		static let id = FieldKey(stringLiteral: "id")
		static let email = FieldKey(stringLiteral: "email")
		static let userID = FieldKey(stringLiteral: "userID")
		static let input = FieldKey(stringLiteral: "input")
		static let createdAt = FieldKey(stringLiteral: "createdAt")
		static let linkResult = FieldKey(stringLiteral: "linkResult")
		static let lastScan = FieldKey(stringLiteral: "lastScan")
	}
}
