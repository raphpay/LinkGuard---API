//
//  Token+Ext.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent

extension Token {
	/// Generate a new token for a user
	/// - Parameter user: The user for which to generate a token
	/// - Returns: A new token for the user
	/// - Throws: An error if the token generation fails
	static func generate(for user: User) throws -> Token {
		let random = [UInt8].random(count: 16).base64
		return try Token(value: random, userID: user.requireID())
	}
}

/// A token used for authentication
/// - Note: This struct represents a token used for authentication.
///    It conforms to the `ModelTokenAuthenticatable` protocol, which provides methods for validating and authenticating tokens.
extension Token: ModelTokenAuthenticatable {
	typealias User = linkguard_api.User

	static var valueKey: KeyPath<Token, Field<String>> {
		\Token.$value
	}

	static var userKey: KeyPath<Token, Parent<User>> {
		\Token.$user
	}

	var isValid: Bool {
		true
	}
}
