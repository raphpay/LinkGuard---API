//
//  TokenController.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent
import Vapor

struct TokenController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		// Group routes under "/api" and apply APIKeyCheckMiddleware for authentication
		let tokens = routes.grouped("api", "tokens")
		// Group routes under "/api/tokens" and apply authentication and user guard middlewares
		// DELETE: Logout
		tokens.delete("logout", ":tokenID", use: logout)

		// Defines middlewares for basic authentication
		let basicAuthMiddleware = User.authenticator()
		let basicAuthGroup = tokens.grouped(basicAuthMiddleware)

		// POST: Login
		basicAuthGroup.post("login", use: login)

		// Defines middlewares for bearer authentication
		let tokenAuthMiddleware = Token.authenticator()
		let guardAuthMiddleware = User.guardMiddleware()
		let tokenAuthGroup = tokens.grouped(tokenAuthMiddleware, guardAuthMiddleware)

		// GET: Get all tokens
		tokenAuthGroup.get("all", use: getTokens)

		// GET: Get a specific token
		tokenAuthGroup.get(":tokenID", use: getTokenByID)

		// DELETE: Remove a specific token
		tokenAuthGroup.delete(":remove", "tokenID", use: removeByID)
	}

	// MARK: - READ
	/// Get all tokens
	/// - Parameter req: The incoming request containing the database connection.
	/// - Returns: An array of `Token.Output` objects representing the retrieved tokens.
	/// - Throws: An error if the database query fails.
	/// - Note: This function retrieves all tokens from the database and returns them as an array of `Token.Output` objects.
	/// - Important: This function should be called with caution and should only be used by administrators.
	@Sendable
	func getTokens(req: Request) async throws -> [Token.Output] {
		let authUser = try req.auth.require(User.self)
		guard authUser.isAdmin else {
			throw Abort(.unauthorized, reason: "unauthorized.role")
		}

		var tokenOutputs: [Token.Output] = []
		let tokens = try await Token.query(on: req.db).all()
		for token in tokens {
			let tokenID = try token.requireID()
			let tokenOutput = try token.toPublicOutput(id: tokenID)
			tokenOutputs.append(tokenOutput)
		}

		return tokenOutputs
	}

	/// Get a specific token by ID
	/// - Parameter req: The incoming request containing the database connection.
	/// - Returns: A `Token.Output` object representing the retrieved token.
	/// - Throws: An error if the token cannot be found or if the database query fails.
	/// - Note: This function retrieves a token by its ID from the database and returns it as a `Token.Output` object.
	/// - Important: This function should be called with caution and should only be used by administrators.
	@Sendable
	func getTokenByID(req: Request) async throws -> Token.Output {
		let authUser = try req.auth.require(User.self)
		guard authUser.isAdmin else {
			throw Abort(.unauthorized, reason: "unauthorized.role")
		}

		guard let token = try await Token.find(req.parameters.get("tokenID"), on: req.db) else {
			throw Abort(.notFound, reason: "notFound.token")
		}

		let tokenID = try token.requireID()
		return try token.toPublicOutput(id: tokenID)
	}

	// MARK: - Login
	/// Login a user and generate a token
	/// - Parameter req: The incoming request containing the database connection.
	/// - Returns: A `Token` object representing the generated token.
	/// - Throws: An error if the user cannot be found or if the password is invalid.
	/// - Note: This function extracts the credentials from the Authorization header using the decodeBasicAuth function.
	///     It then fetches the user based on the email address from the database.
	///     If the user is not found, it throws a `notFound` error.
	///     If the password is invalid, it throws an `unauthorized` error.
	///     If the user has exceeded the maximum login attempts, it throws an `unauthorized` error.
	///     If the last failed login attempt is not nil, it checks if the user is locked out.
	///     If the user is locked out, it throws an `forbidden` error.
	///     If the user is not locked out, it updates the user's last failed login attempt and saves it to the database.
	///     It then generates a new token and saves it to the database.
	///     The function returns the generated token.
	@Sendable
	func login(req: Request) async throws -> Token {
		try await loginToAccount(on: req)
	}

	/// Logout a user and delete the token
	/// - Parameter req: The incoming request containing the token ID.
	/// - Returns: An `HTTPStatus` indicating that no content is being returned (204 No Content).
	/// - Throws: An error if the token cannot be found or if the database deletion fails.
	/// - Note: This function retrieves the token by its ID from the database.
	///     It then deletes the token from the database.
	///     If the token is not found, it throws a `notFound` error.
	@Sendable
	func logout(req: Request) async throws -> HTTPStatus {
		guard let token = try await Token.find(req.parameters.get("tokenID"), on: req.db) else {
			throw Abort(.notFound, reason: "notFound.token")
		}

		try await token.delete(force: true, on: req.db)
		return .noContent
	}

	// MARK: - Delete
	/// Remove a specific token by ID
	/// - Parameter req: The incoming request containing the token ID.
	/// - Returns: An `HTTPResponseStatus` indicating that no content is being returned (204 No Content).
	/// - Throws: An error if the token cannot be found or if the database deletion fails.
	/// - Note: This function retrieves the token by its ID from the database.
	///     It then deletes the token from the database.
	///     If the token is not found, it throws a `notFound` error.
	///     If the database deletion fails, it throws an error.
	/// - Important: This function should be called with caution and should only be used by administrators.
	///     It ensures that the token is deleted from the database.
	///     Use this function only if you want to delete a specific token.
	@Sendable
	func removeByID(req: Request) async throws -> HTTPResponseStatus {
		let authUser = try req.auth.require(User.self)
		guard authUser.isAdmin else {
			throw Abort(.unauthorized, reason: "unauthorized.role")
		}

		let tokenID = try await getTokenID(on: req)
		let token = try await getToken(tokenID, on: req.db)

		try await token.delete(force: true, on: req.db)

		return .noContent
	}
}

extension TokenController {
	/// Get a token by ID
	/// - Parameter id: The ID of the token to be retrieved.
	/// - Parameter db: The database connection to use for retrieving the token.
	/// - Returns: A `Token` object representing the retrieved token.
	/// - Throws: An error if the token cannot be found or if the database query fails.
	/// - Note: This function retrieves a token by its ID from the database and returns it as a `Token` object.
	/// - Important: This function should be called with caution and should only be used by administrators.
	func getToken(_ id: Token.IDValue, on database: any Database) async throws -> Token {
		guard let token = try await Token.find(id, on: database) else {
			throw Abort(.notFound, reason: "notFound.token")
		}
		return token
	}

	func loginToAccount(on req: Request) async throws -> Token {
		// 1. Extract credentials from the Authorization header (Basic Auth)
		let credentials = try decodeBasicAuth(req.headers)

		// Fetch the user based on the email address
		guard let user = try await User.query(on: req.db)
			.filter(\.$email == credentials.mailAddress)
			.first() else {
				throw Abort(.notFound, reason: "notFound.user")
		}

		let newToken = try await verifyPassword(credentials: credentials, user: user, on: req)
		return newToken
	}

	/// Get the token ID from the request parameters.
	/// - Parameter req: The incoming request containing the token ID.
	/// - Returns: A `Token.IDValue` representing the retrieved token ID.
	/// - Throws: An error if the token ID is missing or if the request parameters cannot be parsed.
	/// - Note: This function retrieves the token ID from the request parameters using the `tokenID` key.
	///     It returns the value of the `tokenID` key as a `Token.IDValue`.
	///     If the `tokenID` key is not found, it throws a `badRequest` error.
	///     If the request parameters cannot be parsed, it throws a `badRequest` error.
	/// - Important: This function should be called with caution and should only be used by administrators.
	private func getTokenID(on req: Request) async throws -> Token.IDValue {
		guard let tokenID = req.parameters.get("userID", as: Token.IDValue.self) else {
			throw Abort(.badRequest, reason: "badRequest.missingTokenID")
		}

		return tokenID
	}

	/// Decode the basic authentication credentials from the request headers.
	/// - Parameter headers: The HTTP headers containing the Authorization header.
	/// - Returns: A tuple containing the decoded mail address and password.
	/// - Throws: An error if the Authorization header is missing or if the Authorization header is not in the correct format.
	/// - Note: This function extracts the Authorization header from the request headers.
	///     It checks that the Authorization header starts with "Basic".
	///     If the Authorization header does not start with "Basic", it throws a `unauthorized` error.
	///     It then extracts the base64 encoded part of the Authorization header.
	///     If the base64 encoded part is not valid, it throws a `unauthorized` error.
	///     It then decodes the base64 encoded string into data.
	///     If the decoding fails, it throws a `unauthorized` error.
	///     Finally, it splits the decoded string into username (email) and password.
	///     It returns a tuple containing the decoded mail address and password.
	private func decodeBasicAuth(_ headers: HTTPHeaders) throws -> (mailAddress: String, password: String) {
		// Get the Authorization header from the request headers
		guard let authHeader = headers.first(name: .authorization) else {
			throw Abort(.unauthorized, reason: "unauthorized.missingAuthorizationHeader")
		}

		// Check that the Authorization header starts with "Basic"
		guard authHeader.lowercased().hasPrefix("basic ") else {
			throw Abort(.unauthorized, reason: "unauthorized.invalidAuthorizationHeader")
		}

		// Extract the base64 encoded part of the Authorization header
		let base64String = authHeader.dropFirst(6) // Drop "Basic " prefix

		// Decode the base64 encoded string into data
		guard let data = Data(base64Encoded: String(base64String)) else {
			throw Abort(.unauthorized, reason: "unauthorized.wrongAuthorizationHeader")
		}

		// Convert the decoded data into a UTF-8 string
		guard let decodedString = String(data: data, encoding: .utf8) else {
			throw Abort(.unauthorized, reason: "unauthorized.wrongAuthorizationHeaderData")
		}

		// Split the decoded string into username (email) and password
		let components = decodedString.split(separator: ":")
		guard components.count == 2 else {
			throw Abort(.unauthorized, reason: "unauthorized.invalidAuthorizationFormat")
		}

		// Return the username (email) and password
		let mailAddress = String(components[0])
		let password = String(components[1])

		return (mailAddress, password)
	}

	/// Verify the password for a user.
	/// - Parameters:
	///   - credentials: A tuple containing the mail address and password.
	///   - user: The `User` object representing the user to be checked.
	///   - req: The incoming request containing the database connection.
	/// - Returns: A `Token` object representing the generated token.
	/// - Throws: An error if the password is invalid or if the database query fails.
	/// - Note: This function verifies the password for a user.
	///     It first checks if the password is valid using the Bcrypt library.
	///     If the password is valid, it resets the user's login failed attempts and last failed login attempt.
	///     It then generates a new token and saves it to the database.
	///     The function returns the generated token.
	private func verifyPassword(credentials: (mailAddress: String, password: String), user: User, on req: Request) async throws -> Token {
		// Verify the password
		if try Bcrypt.verify(credentials.password, created: user.passwordHash) {
			// Successful login, reset failed attempts
			try await user.save(on: req.db)

			// Generate or update the token
			let token = try await Token
				.query(on: req.db)
				.filter(\.$user.$id == user.id!)
				.first()

			if let token = token {
				token.value = [UInt8].random(count: 16).base64
				try await token.update(on: req.db)
				return token
			} else {
				// If no token exists, create a new one
				let newToken = try Token.generate(for: user)
				try await newToken.save(on: req.db)
				return newToken
			}
		} else {
			try await user.save(on: req.db)

			// Throw unauthorized error
			throw Abort(.unauthorized, reason: "unauthorized.invalidCredentials")
		}
	}
}
