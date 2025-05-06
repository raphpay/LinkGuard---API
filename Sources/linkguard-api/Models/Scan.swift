//
//  Scan.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent
import Vapor

final class Scan: Model, Content, @unchecked Sendable {
	static let schema = Scan.V20250505.schemaName

	@ID(key: .id)
	var id: UUID?

	@Field(key: Scan.V20250505.input)
	var input: String

	@Timestamp(key: Scan.V20250505.createdAt, on: .create)
	var createdAt: Date?

	@Timestamp(key: Scan.V20250505.lastScan, on : .none)
	var lastScan: Date?

	@OptionalField(key: Scan.V20250505.email)
	var email: String?

	@OptionalParent(key: Scan.V20250505.userID)
	var user: User?

	@OptionalChild(for: \.$scan)
	var linkResult: LinkResult?

	init() { }

	init(id: UUID? = nil,
		 input: String,
		 email: String? = nil,
		 userID: User.IDValue? = nil
	) {
		self.id = id
		self.input = input
		self.email = email
		self.$user.id = userID
	}
}
