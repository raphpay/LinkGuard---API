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
			.schema(User.V20250505.schemaName)
			.id()
			.field(User.V20250505.email, .string, .required)
			.field(User.V20250505.passwordHash, .string, .required)
			.field(User.V20250505.frequency, .string, .required)
			.field(User.V20250505.subscriptionStatus, .string, .required)
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database
			.schema(User.V20250505.schemaName)
			.delete()
	}
}
