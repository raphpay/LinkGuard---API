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

	@Field(key: User.V20250505.frequency)
	var frequency: Frequency

	@Field(key: User.V20250505.subscriptionStatus)
	var subscriptionStatus: SubscriptionStatus

	@Children(for: \.$user)
	var scans: [Scan]

	init() { }

	init(id: UUID? = nil,
		 email: String,
		 passwordHash: String,
		 frequency: Frequency,
		 subscriptionStatus: SubscriptionStatus
	) {
		self.id = id
		self.email = email
		self.passwordHash = passwordHash
		self.frequency = frequency
		self.subscriptionStatus = subscriptionStatus
	}

	func toPublicOutput() throws -> User.PublicOutput {
		let id = try self.requireID()
		return .init(id: id,
					 email: email,
					 frequency: frequency,
					 subscriptionStatus: subscriptionStatus)
	}
}
