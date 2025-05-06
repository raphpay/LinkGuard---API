//
//  User+FieldKeys.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent

extension User {
	enum V20250505 {
		static let schemaName = "users"
		static let id = FieldKey(stringLiteral: "id")
		static let email = FieldKey(stringLiteral: "email")
		static let passwordHash = FieldKey(stringLiteral: "passwordHash")
		static let scans = FieldKey(stringLiteral: "scans")
		static let subscriptionStatus = FieldKey(stringLiteral: "subscriptionStatus")
		static let subscriptionPlanID = FieldKey(stringLiteral: "subscriptionPlanID")
	}
}
