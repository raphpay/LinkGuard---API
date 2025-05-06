//
//  CreateToken.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Foundation
import Fluent

struct CreateToken: AsyncMigration {
	func prepare(on database: any Database) async throws {

		try await database
			.schema(Token.V20250505.schemaName)
			.id()
			.field(Token.V20250505.value, .string, .required)
			.field(Token.V20250505.userID, .uuid, .required,
				   .references(User.V20250505.schemaName, User.V20250505.id)
			)
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database
			.schema(Token.V20250505.schemaName)
			.delete()
	}
}
