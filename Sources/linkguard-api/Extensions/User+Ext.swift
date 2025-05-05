//
//  User+Ext.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent
import Vapor

extension User {
	enum Frequency: String, Codable {
		case daily, weekly, monthly
	}
}

extension User: ModelAuthenticatable {
	static var usernameKey: KeyPath<User, Field<String>> {
		\User.$email
	}

	static var passwordHashKey: KeyPath<User, Field<String>> {
		\User.$passwordHash
	}

	func verify(password: String) throws -> Bool {
		try Bcrypt.verify(password, created: self.passwordHash)
	}
}
