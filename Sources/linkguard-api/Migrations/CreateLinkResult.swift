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
			.schema(LinkResult.V20250505.schemaName)
			.id()
			.field(LinkResult.V20250505.statusCode, .int16, .required)
			.field(LinkResult.V20250505.isAccessible, .bool, .required)
			.field(LinkResult.V20250505.responseTime, .int16, .required)
			.field(LinkResult.V20250505.scanID, .uuid, .required)
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database
			.schema(LinkResult.V20250505.schemaName)
			.delete()
	}
}
