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
			.schema(Scan.V20240207.schemaName)
			.id()
			.field(Scan.V20240207.input, .string, .required)
			.field(Scan.V20240207.createdAt, .datetime, .required)
			.field(Scan.V20240207.email, .string)
			.field(Scan.V20240207.userID, .uuid)
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database
			.schema(Scan.V20240207.schemaName)
			.delete()
	}
}
