//
//  User+FieldKeys.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent

extension User {
	enum V20240207 {
		static let schemaName = "users"
		static let id = FieldKey(stringLiteral: "id")
		static let email = FieldKey(stringLiteral: "email")
		static let passwordHash = FieldKey(stringLiteral: "passwordHash")
		static let frequency = FieldKey(stringLiteral: "frequency")
		static let scans = FieldKey(stringLiteral: "scans")
	}
}
