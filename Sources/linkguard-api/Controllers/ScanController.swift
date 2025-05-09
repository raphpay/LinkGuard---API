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

		scans.post("scan-without-account", use: createWithoutAccount)

		// POST - Create multiple scans and linkresults
		scans.post("bulk", use: createWithBulk)

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
	func createWithoutAccount(req: Request) async throws -> Scan.Output {
		let input = try req.content.decode(Scan.InputWithoutAccount.self)

		guard input.email.isValidEmail() else {
			throw Abort(.badRequest, reason: "badRequest.invalidEmail")
		}

		let existingScanCount = try await Scan.query(on: req.db)
			.filter(\.$email == input.email)
			.count()

		guard existingScanCount == 0 else {
			throw Abort(.forbidden, reason: "forbidden.quotaReached")
		}

		let scan = input.toModel()

		return try await generateScan(scan: scan, email: input.email, on: req)
	}

	/// Creates a new scan for an authenticated user.
	/// - Parameter req: The incoming authenticated request with scan input.
	/// - Returns: The created `Scan` instance.
	/// - Throws: An error if saving or scanning fails.
	@Sendable
	func create(req: Request) async throws -> Scan.Output {
		let authUser = try req.auth.require(User.self)
		let input = try req.content.decode(Scan.Input.self)
		let scan = input.toModel()
		let plan = try await authUser.$subscriptionPlan.get(on: req.db)
		let scans = try await authUser.$scans.get(on: req.db)
		var usersScans = scans
		usersScans.append(scan)

		var linkResult = LinkResult(statusCode: 0, isAccessible: false, responseTime: 0, scanID: UUID())

		let canScan = try await ScanController.checkQuota(with: plan, and: usersScans, on: req)
		if canScan {
			linkResult = try await ScanController.handleScan(scan, on: req)
		} else {
			throw Abort(.forbidden, reason: "forbidden.quotaReached")
		}

		return try scan.toOutput(result: linkResult)
	}

	@Sendable
	func createWithBulk(req: Request) async throws -> [Scan.Output] {
		let input = try req.content.decode(Scan.BulkInput.self)
		guard input.email.isValidEmail() else {
			throw Abort(.badRequest, reason: "badRequest.invalidEmail")
		}

		let existingScanCount = try await Scan.query(on: req.db)
			.filter(\.$email == input.email)
			.count()

		guard existingScanCount == 0 else {
			throw Abort(.forbidden, reason: "forbidden.quotaReached")
		}

		var scans: [Scan.Output] = []
		for url in input.urls {
			let scan = Scan(input: url, email: input.email)
			let output = try await self.generateScan(scan: scan, email: input.email, on: req)
			scans.append(output)
		}

		return scans
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
		let authUser = try req.auth.require(User.self)
		guard authUser.isAdmin else {
			throw Abort(.unauthorized, reason: "unauthorized.role")
		}

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
		let authUser = try req.auth.require(User.self)
		guard authUser.isAdmin else {
			throw Abort(.unauthorized, reason: "unauthorized.role")
		}

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
	private func generateScan(scan: Scan, email: String, on req: Request) async throws -> Scan.Output {
		let linkResult = try await ScanController.handleScan(scan, on: req)

		let emailContent = try await EmailService.generateEmailReportForSingleScan(scan, email: email, on: req.db)
		try await EmailService.sendEmailReport(to: email, with: emailContent, on: req)

		return try scan.toOutput(result: linkResult)
	}

	static func checkQuota(with plan: SubscriptionPlan, and scans: [Scan], on req: Request) async throws -> Bool {
		// Check quota
		if scans.count >= plan.maxUrls {
      // User has reach their scan quota
			return false
		}

		return true
	}

	/// Performs a link scan and stores the result.
	/// - Parameters:
	///   - input: The URL to scan.
	///   - scan: The associated `Scan` object.
	///   - req: The current request context with access to the HTTP client and database.
	/// - Throws: An error if saving the `LinkResult` fails.
	static func handleScan(_ scan: Scan, on req: Request) async throws -> LinkResult {
		let client = req.client

		var statusCode: Int = 0
		var isAccessible = false
		var responseTime: Int = 0

		let start = DispatchTime.now()

		do {
			let response = try await client.get(URI(string: scan.input))
			let end = DispatchTime.now()
			responseTime = Int((end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000) // in ms

			statusCode = Int(response.status.code)
			isAccessible = (200..<400).contains(statusCode)
		} catch {
			let end = DispatchTime.now()
			responseTime = Int((end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000) // in ms
			statusCode = 0
			isAccessible = false
		}

		try await scan.save(on: req.db)

		let linkResult = LinkResult(
			statusCode: statusCode,
			isAccessible: isAccessible,
			responseTime: responseTime,
			scanID: try scan.requireID()
		)

		try await linkResult.save(on: req.db)

		return linkResult
	}

	static func filterRecentScans(with scans: [Scan], and plan: SubscriptionPlan) -> [Scan] {
		// Filter scans within the plan's frequency
		scans.filter { scan in
			guard let scanDate = scan.createdAt else { return false }
			switch plan.scanFrequency {
			case .daily:
				// Only include scans from today
				return Calendar.current.isDateInToday(scanDate)
			case .weekly:
				// If last scan was within 7 days, allow it
				return Calendar.current.dateComponents([.day], from: scanDate, to: .now).day ?? 0 < 7
			case .monthly:
				// If last scan was within 1 month, allow it
				return Calendar.current.dateComponents([.month], from: scanDate, to: .now).month ?? 0 < 1
			}
		}
	}
}
