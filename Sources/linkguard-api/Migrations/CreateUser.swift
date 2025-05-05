//
//  CreateUser.swift
//
//
//  Created by Raphaël Payet on 18/06/2024.
//

import Fluent
import Vapor

struct CreateUser: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database
			.schema(User.V20240207.schemaName)
			.id()
			.field(User.V20240207.email, .string, .required)
			.field(User.V20240207.password, .string, .required)
			.field(User.V20240207.frequency, .string, .required)
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database
			.schema(User.V20240207.schemaName)
			.delete()
	}
}
