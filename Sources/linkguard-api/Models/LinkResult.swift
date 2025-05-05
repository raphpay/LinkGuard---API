//
//  LinkResult.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent
import Vapor

final class LinkResult: Model, Content, @unchecked Sendable {
	static let schema = LinkResult.V20240207.schemaName

	@ID(key: .id)
	var id: UUID?

	@Field(key: LinkResult.V20240207.statusCode)
	var statusCode: String

	@Field(key: LinkResult.V20240207.isAccessible)
	var isAccessible: Bool

	@Parent(key: LinkResult.V20240207.scanID)
	var scan: Scan

	init() { }

	init(id: UUID? = nil,
		 statusCode: String,
		 isAccessible: String,
		 scanID: Scan.IDValue
	) {
		self.id = id
		self.statusCode = statusCode
		self.isAccessible = isAccessible.lowercased() == "true"
		self.$scan.id = scanID
	}
}
