//
//  User.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
	static let schema = User.V20250505.schemaName

	@ID(key: .id)
	var id: UUID?

	@Field(key: User.V20250505.email)
	var email: String

	@Field(key: User.V20250505.passwordHash)
	var passwordHash: String

	@Field(key: User.V20250505.subscriptionStatus)
	var subscriptionStatus: SubscriptionStatus

	@Field(key: User.V20250505.role)
	var role: Role

	@Children(for: \.$user)
	var scans: [Scan]

	@Parent(key: User.V20250505.subscriptionPlanID)
	var subscriptionPlan: SubscriptionPlan

	init() { }

	init(id: UUID? = nil,
		 email: String,
		 passwordHash: String,
		 subscriptionStatus: SubscriptionStatus,
		 role: Role,
		 subscriptionPlanID: SubscriptionPlan.IDValue
	) {
		self.id = id
		self.email = email
		self.passwordHash = passwordHash
		self.subscriptionStatus = subscriptionStatus
		self.role = role
		self.$subscriptionPlan.id = subscriptionPlanID
	}

	func toPublicOutput() throws -> User.PublicOutput {
		let id = try self.requireID()
		return .init(id: id,
					 email: email,
					 subscriptionStatus: subscriptionStatus,
					 role: role,
					 subscriptionPlanID: self.$subscriptionPlan.id
		)
	}
}
