//
//  SubscriptionPlan+FieldKeys.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 06/05/2025.
//

import Fluent

extension SubscriptionPlan {
	enum V20250505 {
		static let schemaName = "subscription_plans"
		static let id = FieldKey(stringLiteral: "id")
		static let name = FieldKey(stringLiteral: "name")
		static let price = FieldKey(stringLiteral: "price")
		static let maxUrls = FieldKey(stringLiteral: "maxUrls")
		static let scanFrequency = FieldKey(stringLiteral: "scanFrequency")
	}
}
