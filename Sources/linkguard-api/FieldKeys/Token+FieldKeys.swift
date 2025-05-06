//
//  Token+FieldKeys.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent

extension Token {
	enum V20250505 {
		static let schemaName = "tokens"

		static let id = FieldKey(stringLiteral: "id")
		static let value = FieldKey(stringLiteral: "value")
		static let userID = FieldKey(stringLiteral: "userID")
	}
}
