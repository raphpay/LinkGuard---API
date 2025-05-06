//
//  CreateSubscriptionPlan.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 06/05/2025.
//



import Fluent
import Vapor

struct CreateSubscriptionPlan: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database
			.schema(SubscriptionPlan.V20250505.schemaName)
			.id()
			.field(SubscriptionPlan.V20250505.name, .string, .required)
			.field(SubscriptionPlan.V20250505.price, .double, .required)
			.field(SubscriptionPlan.V20250505.maxUrls, .int64, .required)
			.field(SubscriptionPlan.V20250505.scanFrequency, .string, .required)
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database
			.schema(SubscriptionPlan.V20250505.schemaName)
			.delete()
	}
}
