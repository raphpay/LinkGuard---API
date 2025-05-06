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

	enum SubscriptionStatus: String, Codable {
		case free           // Default for users not paying
		case trial          // Trial period before payment starts
		case active         // Currently paying and within term
		case pastDue        // Payment failed, grace period
		case canceled       // User or system canceled subscription
		case expired        // Subscription ended, no auto-renew
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
