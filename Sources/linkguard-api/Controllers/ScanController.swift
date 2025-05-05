//
//  ScanController.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent
import Vapor

struct ScanController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		// Group routes under "/api"
		let scans = routes.grouped("api", "scans")
		// Group routes under "/api/scans" and apply authentication and user guard middlewares
		scans.post("scan-without-account", use: createWithoutAccount)

		// Defines middlewares for bearer authentication
		let tokenAuthMiddleware = Token.authenticator()
		let guardAuthMiddleware = User.guardMiddleware()
		let scanAuthGroup = scans.grouped(tokenAuthMiddleware, guardAuthMiddleware)

		// POST: Save a scan
		scanAuthGroup.post(use: create)

		// GET: Get a specific scan
		scanAuthGroup.get(":scanID", use: getScanByID)

		// DELETE: Remove a specific token
		scanAuthGroup.delete(":scanID", use: removeByID)
	}

	// MARK: - CREATE
	@Sendable
	func createWithoutAccount(req: Request) async throws -> Scan {
		let input = try req.content.decode(Scan.InputWithoutAccount.self)
		let scan = input.toModel()

		guard input.email.isValidEmail() else {
			throw Abort(.badRequest, reason: "badRequest.invalidEmail")
		}

		try await scan.save(on: req.db)
		let scanID = try scan.requireID()
		try await handleScan(input.input, with: scanID, on: req)

		return scan
	}

	@Sendable
	func create(req: Request) async throws -> Scan {
		let input = try req.content.decode(Scan.Input.self)
		let scan = input.toModel()

		try await scan.save(on: req.db)
		let scanID = try scan.requireID()
		try await handleScan(input.input, with: scanID, on: req)

		return scan
	}

	// MARK: - READ
	/// Get a specific scan by ID
	/// - Parameter req: The incoming request containing the database connection.
	/// - Returns: A `Scan.Output` object representing the retrieved scan.
	/// - Throws: An error if the scan cannot be found or if the database query fails.
	/// - Note: This function retrieves a scan by its ID from the database and returns it as a `Scan` object.
	/// - Important: This function should be called with caution and should only be used by administrators.
	@Sendable
	func getScanByID(req: Request) async throws -> Scan {
		guard let scan = try await Scan.find(req.parameters.get("scanID"), on: req.db) else {
			throw Abort(.notFound, reason: "notFound.scan")
		}

		return scan
	}

	// MARK: - Delete
	/// Remove a specific scan by ID
	/// - Parameter req: The incoming request containing the scan ID.
	/// - Returns: An `HTTPResponseStatus` indicating that no content is being returned (204 No Content).
	/// - Throws: An error if the scan cannot be found or if the database deletion fails.
	/// - Note: This function retrieves the scan by its ID from the database.
	///     It then deletes the scan from the database.
	///     If the scan is not found, it throws a `notFound` error.
	///     If the database deletion fails, it throws an error.
	/// - Important: This function should be called with caution and should only be used by administrators.
	///     It ensures that the scan is deleted from the database.
	///     Use this function only if you want to delete a specific scan.
	@Sendable
	func removeByID(req: Request) async throws -> HTTPResponseStatus {
		let scanID = try await getScanID(on: req)
		let scan = try await getScan(scanID, on: req.db)

		try await scan.delete(on: req.db)
		if let linkResult = try await scan.$linkResult.get(on: req.db) {
			let linkResultID = try linkResult.requireID()
			_ = try await LinkResultController().delete(linkResultID, on: req)
		}

		return .noContent
	}
}

extension ScanController {
	/// Get a scan by ID
	/// - Parameter id: The ID of the scan to be retrieved.
	/// - Parameter db: The database connection to use for retrieving the scan.
	/// - Returns: A `Scan` object representing the retrieved scan.
	/// - Throws: An error if the scan cannot be found or if the database query fails.
	/// - Note: This function retrieves a scan by its ID from the database and returns it as a `Scan` object.
	func getScan(_ id: Scan.IDValue, on database: any Database) async throws -> Scan {
		guard let scan = try await Scan.find(id, on: database) else {
			throw Abort(.notFound, reason: "notFound.scan")
		}
		return scan
	}

	/// Get the scan ID from the request parameters.
	/// - Parameter req: The incoming request containing the scan ID.
	/// - Returns: A `Scan.IDValue` representing the retrieved scan ID.
	/// - Throws: An error if the scan ID is missing or if the request parameters cannot be parsed.
	/// - Note: This function retrieves the scan ID from the request parameters using the `scanID` key.
	///     It returns the value of the `scanID` key as a `Scan.IDValue`.
	///     If the `scanID` key is not found, it throws a `badRequest` error.
	///     If the request parameters cannot be parsed, it throws a `badRequest` error.
	private func getScanID(on req: Request) async throws -> Scan.IDValue {
		guard let scanID = req.parameters.get("scanID", as: Scan.IDValue.self) else {
			throw Abort(.badRequest, reason: "badRequest.missingScanID")
		}

		return scanID
	}
}

extension ScanController {
	private func handleScan(_ input: String, with scanID: Scan.IDValue, on req: Request) async throws {
		let client = req.client

		var statusCode: Int = 0
		var isAccessible = false

		do {
			let response = try await client.get(URI(string: input))
			statusCode = Int(response.status.code)
			isAccessible = (200..<400).contains(statusCode)
		} catch {
			// URL inaccessible
			statusCode = 0
			isAccessible = false
		}

		let linkResult = LinkResult(statusCode: statusCode, isAccessible: isAccessible, scanID: scanID)
		try await linkResult.save(on: req.db)
	}
}
