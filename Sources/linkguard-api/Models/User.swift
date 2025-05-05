//
//  User.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
	static let schema = User.V20240207.schemaName

	@ID(key: .id)
	var id: UUID?

	@Field(key: User.V20240207.email)
	var email: String

	@Field(key: User.V20240207.passwordHash)
	var passwordHash: String

	@Field(key: User.V20240207.frequency)
	var frequency: Frequency

	init() { }

	init(id: UUID? = nil,
		 email: String,
		 passwordHash: String,
		 frequency: Frequency
	) {
		self.id = id
		self.email = email
		self.passwordHash = passwordHash
		self.frequency = frequency
	}
}
