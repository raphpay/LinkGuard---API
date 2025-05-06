//
//  LinkResultController.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent
import Vapor

struct LinkResultController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		// Group routes under "/api"
		let linkResults = routes.grouped("api", "linkResults")
		// Defines middlewares for bearer authentication
		let tokenAuthMiddleware = Token.authenticator()
		let guardAuthMiddleware = User.guardMiddleware()
		let linkResultAuthGroup = linkResults.grouped(tokenAuthMiddleware, guardAuthMiddleware)

		// GET: Get a specific link result
		linkResultAuthGroup.get(":linkResultID", use: getByID)

		// DELETE: Remove a specific token
		linkResultAuthGroup.delete(":linkResultID", use: removeByID)
	}

	// MARK: - READ
	/// Get a specific linkResult by ID
	/// - Parameter req: The incoming request containing the database connection.
	/// - Returns: A `LinkResult` object representing the retrieved linkResult.
	/// - Throws: An error if the linkResult cannot be found or if the database query fails.
	/// - Note: This function retrieves a linkResult by its ID from the database and returns it as a `LinkResult` object.
	/// - Important: This function should be called with caution and should only be used by administrators.
	@Sendable
	func getByID(req: Request) async throws -> LinkResult {
		let authUser = try req.auth.require(User.self)
		guard authUser.isAdmin else {
			throw Abort(.unauthorized, reason: "unauthorized.role")
		}

		guard let linkResult = try await LinkResult.find(req.parameters.get("linkResultID"), on: req.db) else {
			throw Abort(.notFound, reason: "notFound.linkResult")
		}

		return linkResult
	}

	// MARK: - Delete
	/// Remove a specific linkResult by ID
	/// - Parameter req: The incoming request containing the linkResult ID.
	/// - Returns: An `HTTPResponseStatus` indicating that no content is being returned (204 No Content).
	/// - Throws: An error if the linkResult cannot be found or if the database deletion fails.
	/// - Note: This function retrieves the linkResult by its ID from the database.
	///     It then deletes the linkResult from the database.
	///     If the linkResult is not found, it throws a `notFound` error.
	///     If the database deletion fails, it throws an error.
	/// - Important: This function should be called with caution and should only be used by administrators.
	///     It ensures that the linkResult is deleted from the database.
	///     Use this function only if you want to delete a specific linkResult.
	@Sendable
	func removeByID(req: Request) async throws -> HTTPResponseStatus {
		let authUser = try req.auth.require(User.self)
		guard authUser.isAdmin else {
			throw Abort(.unauthorized, reason: "unauthorized.role")
		}
		
		let linkResultID = try await getLinkResultID(on: req)

		return try await delete(linkResultID, on: req)
	}
}

extension LinkResultController {
	/// Get a linkResult by ID
	/// - Parameter id: The ID of the linkResult to be retrieved.
	/// - Parameter db: The database connection to use for retrieving the linkResult.
	/// - Returns: A `LinkResult` object representing the retrieved linkResult.
	/// - Throws: An error if the linkResult cannot be found or if the database query fails.
	/// - Note: This function retrieves a linkResult by its ID from the database and returns it as a `LinkResult` object.
	func getLinkResult(_ id: LinkResult.IDValue, on database: any Database) async throws -> LinkResult {
		guard let linkResult = try await LinkResult.find(id, on: database) else {
			throw Abort(.notFound, reason: "notFound.linkResult")
		}
		return linkResult
	}

	/// Get the linkResult ID from the request parameters.
	/// - Parameter req: The incoming request containing the linkResult ID.
	/// - Returns: A `LinkResult.IDValue` representing the retrieved linkResult ID.
	/// - Throws: An error if the linkResult ID is missing or if the request parameters cannot be parsed.
	/// - Note: This function retrieves the linkResult ID from the request parameters using the `linkResultID` key.
	///     It returns the value of the `linkResultID` key as a `LinkResult.IDValue`.
	///     If the `linkResultID` key is not found, it throws a `badRequest` error.
	///     If the request parameters cannot be parsed, it throws a `badRequest` error.
	private func getLinkResultID(on req: Request) async throws -> LinkResult.IDValue {
		guard let linkResultID = req.parameters.get("linkResultID", as: LinkResult.IDValue.self) else {
			throw Abort(.badRequest, reason: "badRequest.missingLinkResultID")
		}

		return linkResultID
	}

	/// Deletes a specific `LinkResult` from the database.
	/// - Parameters:
	///   - id: The ID of the `LinkResult` to delete.
	///   - req: The request context containing the database.
	/// - Returns: A `HTTPResponseStatus.noContent` status on successful deletion.
	/// - Throws: `.notFound` if the `LinkResult` is not found or an error if the delete fails.
	/// - Note: This is a helper method used to encapsulate deletion logic, separating retrieval and deletion steps.
	/// - Important: This function should only be called when you are certain the caller is authorized to delete the resource.
	func delete(_ id: LinkResult.IDValue, on req: Request) async throws -> HTTPResponseStatus {
		let linkResult = try await getLinkResult(id, on: req.db)

		try await linkResult.delete(on: req.db)

		return .noContent
	}
}
