//
//  UserController.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent
import Vapor
import Smtp

struct UserController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		// Group the routes under the "api" path
		let users = routes.grouped("api", "users")
		// POST
		try registerPostRoutes(users)
		// GET
		try registerGetRoutes(users)
		// UPDATE
		try registerUpdateRoutes(users)
	}
}

extension UserController {
	private func registerPostRoutes(_ routes: any RoutesBuilder) throws {
		// POST: Create a new user without authentication
		routes.post("register", use: create)
	}

	private func registerGetRoutes(_ routes: any RoutesBuilder) throws {
		let tokenAuthMiddleware = Token.authenticator()
		let guardAuthMiddleware = User.guardMiddleware()
		let tokenAuthGroup = routes.grouped(tokenAuthMiddleware, guardAuthMiddleware)

		// GET: Retrieve all users
		tokenAuthGroup.get(use: getAll)

		// GET: Retrieve a specific user by ID
		tokenAuthGroup.get(":userID", use: getUser)

		// GET: Retrieve the scans of a user by ID
		tokenAuthGroup.get("scans", ":userID", use: getUserScans)
	}

	private func registerUpdateRoutes(_ routes: any RoutesBuilder) throws {
		let tokenAuthMiddleware = Token.authenticator()
		let guardAuthMiddleware = User.guardMiddleware()
		let tokenAuthGroup = routes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
		// UPDATE: Modify a user
		tokenAuthGroup.put(":userID", use: update)
		// Update Modify password
		tokenAuthGroup.put("password", use: changePassword)
	}
}

extension UserController {
	// MARK: - CREATE
	/// Create a new user
	/// - Parameter req: The incoming request containing the user information.
	/// - Returns: A `User.PublicOutput` object representing the created user.
	/// - Throws: An error if the user cannot be created or if the database query fails.
	/// - Note: This function validates the input parameters and creates a new user with the provided information.
	///        It also hashes the password before saving it to the database.
	@Sendable
	func create(req: Request) async throws -> Token {
		let input = try req.content.decode(User.Input.self)
		_ = try await create(input: input, on: req.db)
		return try await TokenController().loginToAccount(on: req)
	}

	// MARK: - READ
	/// Retrieve all users
	/// - Parameter req: The incoming request.
	/// - Returns: An array of `User.PublicOutput` objects representing the retrieved users.
	/// - Throws: An error if the database query fails.
	/// - Note: This function fetches all users from the database and returns their public output.
	///        It is intended for use by admin users only.
	/// - Warning: This function should only be called by admin users.
	@Sendable
	func getAll(req: Request) async throws -> [User.PublicOutput] {
		var users: [User.PublicOutput] = []
		let savedUsers = try await User.query(on: req.db).all()
		for user in savedUsers {
			let userOutput = try user.toPublicOutput()
			users.append(userOutput)
		}

		return users
	}

	/// Retrieve a specific user by ID
	/// - Parameter req: The incoming request containing the user ID.
	/// - Returns: A `User.PublicOutput` object representing the retrieved user.
	/// - Throws: An error if the user cannot be found or if the database query fails.
	@Sendable
	func getUser(req: Request) async throws -> User.PublicOutput {
		let userID = try await getUserID(on: req)
		let user = try await getUser(userID, on: req)
		return try user.toPublicOutput()
	}

	/// Retrieve the scans of a specific user by ID
	/// - Parameter req: The incoming request containing the user ID.
	/// - Returns: A `[Scan]` object representing the retrieved scans.
	/// - Throws: An error if the user cannot be found or if the database query fails.
	@Sendable
	func getUserScans(req: Request) async throws -> [Scan.Output] {
		let userID = try await getUserID(on: req)
		let user = try await getUser(userID, on: req)
		let scans = try await user.$scans.get(on: req.db)
		var scanOutputs = [Scan.Output]()
		for scan in scans {
			guard let linkResult = try await scan.$linkResult.get(on: req.db) else {
				throw Abort(.notFound, reason: "notFound.linkResult")
			}

			let scanOutput = try scan.toOutput(result: linkResult)
			scanOutputs.append(scanOutput)
		}

		return scanOutputs
	}


	// MARK: - UPDATE
	/// Update a user
	/// - Parameter req: The incoming request containing the user ID and updated information.
	/// - Returns: A `User.PublicOutput` object representing the updated user.
	/// - Throws: An error if the user cannot be found or if the database update fails.
	/// - Note: This function updates the user with the provided information.
	///     It first retrieves the user by its ID from the database.
	///     It then updates the user with the provided information.
	///     If the user is not found, it throws a `notFound` error.
	///     If the database update fails, it throws an error.
	///     If the user does not have the required role to perform the update, it throws an `unauthorized` error.
	@Sendable
	func update(req: Request) async throws -> User.PublicOutput {
		let userID = try await getUserID(on: req)
		let user = try await getUser(userID, on: req)
		var updatedUser = user

		let input = try req.content.decode(User.UpdateInput.self)

		try await UserUpdateMiddleware().validate(userInput: input, on: req.db)
		updatedUser = input.update(updatedUser)

		try await updatedUser.update(on: req.db)

		return try user.toPublicOutput()
	}

	/// Update a user's password
	/// - Parameter req: The incoming request containing the user ID and updated information.
	/// - Returns: A `User.PublicOutput` object representing the updated user.
	/// - Throws: An error if the user cannot be found or if the database update fails.
	/// - Note: This function updates the user with the provided information.
	///     It first retrieves the user by its ID from the database.
	///     It then updates the user with the provided information.
	///     If the user is not found, it throws a `notFound` error.
	///     If the database update fails, it throws an error.
	///     If the user does not have the required role to perform the update, it throws an `unauthorized` error.
	@Sendable
	func updatePassword(req: Request) async throws -> User.PublicOutput {
		let userID = try await getUserID(on: req)
		let user = try await getUser(userID, on: req)
		var updatedUser = user

		let input = try req.content.decode(User.UpdatePasswordInput.self)

		if let password = input.password {
			// Validate password
			do {
				try PasswordValidation().validatePassword(password)
			} catch {
				throw error
			}
			let passwordHash = try Bcrypt.hash(password)

			updatedUser = input.update(updatedUser, passwordHash: passwordHash)
		}

		try await updatedUser.update(on: req.db)

		return try user.toPublicOutput()
	}

	@Sendable
	func changePassword(_ req: Request) async throws -> Token {
		let user = try req.auth.require(User.self)
		let input = try req.content.decode(User.ChangePasswordInput.self)

		// 1. Verify current password
		guard try Bcrypt.verify(input.currentPassword, created: user.passwordHash) else {
			throw Abort(.unauthorized, reason: "unauthorized.incorrectPassword")
		}

		// 2. Check new password strength or duplication
		guard input.currentPassword != input.newPassword else {
			throw Abort(.badRequest, reason: "badRequest.passwordDuplication")
		}

		// 3. Hash new password and update
		user.passwordHash = try Bcrypt.hash(input.newPassword)
		try await user.update(on: req.db)

		// 4. Invalidate tokens/sessions here
		let token = try await TokenController().generateToken(for: user, on: req)

		// 5. Send confirmation email
		guard let sender = Environment.get("BREVO_SENDER") else {
			throw Abort(.internalServerError, reason: "Missing Brevo credentials")
		}

		let emailObject = try Email(
			from: EmailAddress(address: sender, name: "LinkGuard"),
			to: [EmailAddress(address: user.email)],
			subject: "Votre rapport de scan LinkGuard",
			body: "Mot de passe changé avec succès"
		)

		try await req.application.smtp.send(emailObject)

		return token
	}
}

// MARK: - Utils
extension UserController {
	/// Create a new user
	/// - Parameters:
	///   - input: The `User.Input` containing the user information.
	///   - db: The database connection to use for creating the user.
	/// - Returns: A `User.PublicOutput` object representing the created user.
	/// - Throws: An error if the user cannot be created or if the database query fails.
	/// - Note: This function validates the input parameters and creates a new user with the provided information.
	///        It also hashes the password before saving it to the database.
	func create(input: User.Input, on db: any Database) async throws -> User.PublicOutput {
		try await UserMiddleware().validate(userInput: input, on: db)
		// Validate password
		do {
			try PasswordValidation().validatePassword(input.password)
		} catch {
			throw error
		}
		let passwordHash = try Bcrypt.hash(input.password)
		let user = input.toModel(with: passwordHash)

		try await user.save(on: db)
		return try user.toPublicOutput()
	}

	/// Retrieve a user by ID
	/// - Parameters:
	///   - id: The ID of the user to be retrieved.
	///   - req: The incoming request containing the database connection.
	/// - Returns: A `User` object representing the retrieved user.
	/// - Throws: An error if the user cannot be found or if the database query fails.
	func getUser(_ id: User.IDValue, on req: Request) async throws -> User {
		guard let user = try await User.find(id, on: req.db) else {
			throw Abort(.notFound, reason: "notFound.user")
		}

		return user
	}
}

// MARK: - Private Utils
extension UserController {
	/// Retrieve the user ID from the request parameters.
	/// - Parameter req: The incoming request containing the user ID.
	/// - Returns: A `User.IDValue` representing the retrieved user ID.
	/// - Throws: An error if the user ID is missing or if the request parameters cannot be parsed.
	/// - Note: This function retrieves the user ID from the request parameters using the `userID` key.
	///     It returns the value of the `userID` key as a `User.IDValue`.
	///     If the `userID` key is not found, it throws a `badRequest` error.
	private func getUserID(on req: Request) async throws -> User.IDValue {
		guard let userID = req.parameters.get("userID", as: User.IDValue.self) else {
			throw Abort(.badRequest, reason: "badRequest.missingUserID")
		}

		return userID
	}
}
