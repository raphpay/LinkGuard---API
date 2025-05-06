//
//  CreateScan.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//


import Fluent
import Vapor

struct CreateScan: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database
			.schema(Scan.V20250505.schemaName)
			.id()
			.field(Scan.V20250505.input, .string, .required)
			.field(Scan.V20250505.createdAt, .datetime, .required)
			.field(Scan.V20250505.email, .string)
			.field(Scan.V20250505.userID, .uuid)
			.field(Scan.V20250505.lastScan, .datetime, .required)
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database
			.schema(Scan.V20250505.schemaName)
			.delete()
	}
}
