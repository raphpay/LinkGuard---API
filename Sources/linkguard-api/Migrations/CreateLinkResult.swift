//
//  CreateLinkResult.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent

struct CreateLinkResult: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database
			.schema(LinkResult.V20240207.schemaName)
			.id()
			.field(LinkResult.V20240207.statusCode, .string, .required)
			.field(LinkResult.V20240207.isAccessible, .bool, .required)
			.field(LinkResult.V20240207.scanID, .uuid, .required)
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database
			.schema(LinkResult.V20240207.schemaName)
			.delete()
	}
}
