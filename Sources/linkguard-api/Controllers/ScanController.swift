//
//  ScanController.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent
import Vapor

struct ScanController: RouteCollection {
	/// Registers all scan-related routes with the application.
	/// - Parameter routes: The base `RoutesBuilder` to register routes to.
	/// - Throws: An error if route registration fails.
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
	/// Creates a new scan without a user account.
	/// - Parameter req: The incoming request containing scan input and user email.
	/// - Returns: A newly created `Scan` instance.
	/// - Throws: `.badRequest` if the email is invalid or if saving or scanning fails.
	@Sendable
	func createWithoutAccount(req: Request) async throws -> Scan {
		let input = try req.content.decode(Scan.InputWithoutAccount.self)
		let scan = input.toModel()

		guard input.email.isValidEmail() else {
			throw Abort(.badRequest, reason: "badRequest.invalidEmail")
		}

		try await ScanController.handleScan(input.input, with: scan, on: req)

		return scan
	}

	/// Creates a new scan for an authenticated user.
	/// - Parameter req: The incoming authenticated request with scan input.
	/// - Returns: The created `Scan` instance.
	/// - Throws: An error if saving or scanning fails.
	@Sendable
	func create(req: Request) async throws -> Scan {
		let input = try req.content.decode(Scan.Input.self)
		let scan = input.toModel()

		try await ScanController.handleScan(input.input, with: scan, on: req)

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

	/// Deletes a specific scan and its associated `LinkResult`.
	/// - Parameter req: The incoming request with scan ID parameter.
	/// - Returns: `.noContent` on successful deletion.
	/// - Throws: `.notFound` if the scan is not found, or any database deletion error.
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
	/// Performs a link scan and stores the result.
	/// - Parameters:
	///   - input: The URL to scan.
	///   - scan: The associated `Scan` object.
	///   - req: The current request context with access to the HTTP client and database.
	/// - Throws: An error if saving the `LinkResult` fails.
	static func handleScan(_ input: String, with scan: Scan, on req: Request) async throws {
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
		
		try await scan.save(on: req.db)

		let linkResult = LinkResult(statusCode: statusCode, isAccessible: isAccessible, scanID: try scan.requireID())

		try await linkResult.save(on: req.db)
	}
}
