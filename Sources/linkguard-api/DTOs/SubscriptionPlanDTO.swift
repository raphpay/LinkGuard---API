//
//  SubscriptionPlanDTO.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 06/05/2025.
//

import Fluent
import Vapor

extension SubscriptionPlan {
	struct Input: Content {
		let name: Name
		let price: Double
		let maxUrls: Int
		let scanFrequency: ScanFrequency

		func toModel() -> SubscriptionPlan {
			.init(name: name, price: price, maxUrls: maxUrls, scanFrequency: scanFrequency)
		}
	}
}

extension SubscriptionPlan {
	struct UpdateInput: Content {
		let name: Name?
		let price: Double?
		let maxUrls: Int?
		let scanFrequency: ScanFrequency?

		/// Updates the given `User` model by applying all non-nil fields from this `UpdateInput`.
		///
		/// Only the values that are not nil will overwrite the corresponding fields in the existing model.
		/// This allows for partial updates.
		///
		/// - Parameters:
		///   - user: The existing `User` model to be updated.
		///   - db: A database reference (not currently used in this function).
		/// - Returns: The updated `User` model.
		func update(_ subscriptionPlan: SubscriptionPlan) -> SubscriptionPlan {
			let updatedSubscriptionPlan = subscriptionPlan

			applyIfPresent(name) { subscriptionPlan.name = $0 }
			applyIfPresent(price) { subscriptionPlan.price = $0 }
			applyIfPresent(maxUrls) { subscriptionPlan.maxUrls = $0 }
			applyIfPresent(scanFrequency) { subscriptionPlan.scanfrequency = $0 }

			return updatedSubscriptionPlan
		}

		/// Applies the given closure to a value if it is non-nil.
		///
		/// This utility is used to selectively update fields in an `Implant` only when new values are provided.
		///
		/// - Parameters:
		///   - value: An optional value to check.
		///   - apply: A closure that updates a field with the unwrapped value.
		private func applyIfPresent<T>(_ value: T?, _ apply: (T) -> Void) {
			if let value = value {
				apply(value)
			}
		}
	}
}
