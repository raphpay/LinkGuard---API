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
			.schema(Token.V20240207.schemaName)
			.id()
			.field(Token.V20240207.value, .string, .required)
			.field(Token.V20240207.userID, .uuid, .required,
				   .references(User.V20240207.schemaName, User.V20240207.id)
			)
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database
			.schema(Token.V20240207.schemaName)
			.delete()
	}
}
