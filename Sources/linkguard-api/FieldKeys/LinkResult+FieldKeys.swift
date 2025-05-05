//
//  LinkResult+FieldKeys.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent

extension LinkResult {
	enum V20240207 {
		static let schemaName = "linkResults"
		static let id = FieldKey(stringLiteral: "id")
		static let statusCode = FieldKey(stringLiteral: "statusCode")
		static let isAccessible = FieldKey(stringLiteral: "isAccessible")
		static let scanID = FieldKey(stringLiteral: "scanID")
	}
}
