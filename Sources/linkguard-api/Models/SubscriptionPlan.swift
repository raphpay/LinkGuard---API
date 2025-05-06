//
//  SubscriptionPlan.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 06/05/2025.
//

import Fluent
import Vapor

final class SubscriptionPlan: Model, Content, @unchecked Sendable {
	static let schema = SubscriptionPlan.V20250505.schemaName

	@ID(key: .id)
	var id: UUID?

	@Field(key: SubscriptionPlan.V20250505.name)
	var name: Name

	@Field(key: SubscriptionPlan.V20250505.price)
	var price: Double

	@Field(key: SubscriptionPlan.V20250505.maxUrls)
	var maxUrls: Int

	@Field(key: SubscriptionPlan.V20250505.scanFrequency)
	var scanfrequency: ScanFrequency

	@Children(for: \.$subscriptionPlan)
	var users: [User]

	init() { }

	init(id: UUID? = nil,
		 name: Name,
		 price: Double,
		 maxUrls: Int,
		 scanFrequency: ScanFrequency
	) {
		self.id = id
		self.name = name
		self.price = price
		self.maxUrls = maxUrls
		self.scanfrequency = scanFrequency
	}
}
