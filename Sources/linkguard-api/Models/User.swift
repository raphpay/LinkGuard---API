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

	@Field(key: User.V20240207.password)
	var password: String

	@Field(key: User.V20240207.frequency)
	var frequency: String

	init() { }

	init(id: UUID? = nil,
		 email: String,
		 password: String,
		 frequency: String
	) {
		self.id = id
		self.email = email
		self.password = password
		self.frequency = frequency
	}
}
