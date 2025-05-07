//
//  SubscriptionPlanController.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 06/05/2025.
//

import Fluent
import Vapor

struct SubscriptionPlanController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		// Group the routes under the "api" path
		let subscriptionPlans = routes.grouped("api", "subscriptionPlans")
		// POST
		try registerPostRoutes(subscriptionPlans)
		// GET
		try registerGetRoutes(subscriptionPlans)
		// UPDATE
		try registerUpdateRoutes(subscriptionPlans)
	}
}

extension SubscriptionPlanController {
	private func registerPostRoutes(_ routes: any RoutesBuilder) throws {
		// POST: Create a new user without authentication
		routes.post(use: create)
	}

	private func registerGetRoutes(_ routes: any RoutesBuilder) throws {
		// GET: Retrieve all subscription plans
		routes.get(use: getAll)

		let tokenAuthMiddleware = Token.authenticator()
		let guardAuthMiddleware = User.guardMiddleware()
		let tokenAuthGroup = routes.grouped(tokenAuthMiddleware, guardAuthMiddleware)

		// GET: Retrieve a specific user by ID
		tokenAuthGroup.get(":subscriptionPlanID", use: getByID)
	}

	private func registerUpdateRoutes(_ routes: any RoutesBuilder) throws {
		let tokenAuthMiddleware = Token.authenticator()
		let guardAuthMiddleware = User.guardMiddleware()
		let tokenAuthGroup = routes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
		// UPDATE: Modify a user
		tokenAuthGroup.put(":subscriptionPlanID", use: update)
	}
}

extension SubscriptionPlanController {
	// MARK: - CREATE
	/// Create a new user
	/// - Parameter req: The incoming request containing the user information.
	/// - Returns: A `User.PublicOutput` object representing the created user.
	/// - Throws: An error if the user cannot be created or if the database query fails.
	/// - Note: This function validates the input parameters and creates a new user with the provided information.
	///        It also hashes the password before saving it to the database.
	@Sendable
	func create(req: Request) async throws -> SubscriptionPlan {
		let authUser = try req.auth.require(User.self)
		guard authUser.isAdmin else {
			throw Abort(.unauthorized, reason: "unauthorized.role")
		}

		let input = try req.content.decode(SubscriptionPlan.Input.self)
		let output = input.toModel()
		try await output.save(on: req.db)
		return output
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
	func getAll(req: Request) async throws -> [SubscriptionPlan] {
		try await SubscriptionPlan.query(on: req.db).all()
	}

	/// Retrieve a specific user by ID
	/// - Parameter req: The incoming request containing the user ID.
	/// - Returns: A `User.PublicOutput` object representing the retrieved user.
	/// - Throws: An error if the user cannot be found or if the database query fails.
	@Sendable
	func getByID(req: Request) async throws -> SubscriptionPlan {
		let subscriptionPlanID = try await getSubscriptionPlanID(on: req)
		let subscriptionPlan = try await getSubscriptionPlan(subscriptionPlanID, on: req)
		return subscriptionPlan
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
	func update(req: Request) async throws -> SubscriptionPlan {
		let authUser = try req.auth.require(User.self)
		guard authUser.isAdmin else {
			throw Abort(.unauthorized, reason: "unauthorized.role")
		}
		
		let subscriptionPlanID = try await getSubscriptionPlanID(on: req)
		let subscriptionPlan = try await getSubscriptionPlan(subscriptionPlanID, on: req)
		var updatedSubscriptionPlan = subscriptionPlan

		let input = try req.content.decode(SubscriptionPlan.UpdateInput.self)

//		try await UserUpdateMiddleware().validate(userInput: input, on: req.db
		updatedSubscriptionPlan = input.update(updatedSubscriptionPlan)

		try await updatedSubscriptionPlan.update(on: req.db)

		return updatedSubscriptionPlan
	}
}

// MARK: - Utils
extension SubscriptionPlanController {
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
	func getSubscriptionPlan(_ id: SubscriptionPlan.IDValue, on req: Request) async throws -> SubscriptionPlan {
		guard let subscriptionPlan = try await SubscriptionPlan.find(id, on: req.db) else {
			throw Abort(.notFound, reason: "notFound.subscriptionPlan")
		}

		return subscriptionPlan
	}
}

// MARK: - Private Utils
extension SubscriptionPlanController {
	/// Retrieve the user ID from the request parameters.
	/// - Parameter req: The incoming request containing the user ID.
	/// - Returns: A `User.IDValue` representing the retrieved user ID.
	/// - Throws: An error if the user ID is missing or if the request parameters cannot be parsed.
	/// - Note: This function retrieves the user ID from the request parameters using the `userID` key.
	///     It returns the value of the `userID` key as a `User.IDValue`.
	///     If the `userID` key is not found, it throws a `badRequest` error.
	private func getSubscriptionPlanID(on req: Request) async throws -> SubscriptionPlan.IDValue {
		guard let subscriptionPlanID = req.parameters.get("subscriptionPlanID", as: SubscriptionPlan.IDValue.self) else {
			throw Abort(.badRequest, reason: "badRequest.missingSubscriptionPlanID")
		}

		return subscriptionPlanID
	}
}
