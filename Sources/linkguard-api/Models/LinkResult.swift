//
//  LinkResult.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent
import Vapor

final class LinkResult: Model, Content, @unchecked Sendable {
	static let schema = LinkResult.V20250505.schemaName

	@ID(key: .id)
	var id: UUID?

	@Field(key: LinkResult.V20250505.statusCode)
	var statusCode: Int

	@Field(key: LinkResult.V20250505.isAccessible)
	var isAccessible: Bool

	@Field(key: LinkResult.V20250505.responseTime)
	var responseTime: Int

	@Parent(key: LinkResult.V20250505.scanID)
	var scan: Scan

	init() { }

	init(id: UUID? = nil,
		 statusCode: Int,
		 isAccessible: Bool,
		 responseTime: Int,
		 scanID: Scan.IDValue
	) {
		self.id = id
		self.statusCode = statusCode
		self.isAccessible = isAccessible
		self.responseTime = responseTime
		self.$scan.id = scanID
	}
}
