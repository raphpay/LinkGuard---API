//
//  File.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent
import Vapor

extension User {
	struct Input: Content {
		let email: String
		let password: String
		let subscriptionStatus: SubscriptionStatus
		let subscriptionPlanID: SubscriptionPlan.IDValue
		let role: Role

		func toModel(with passwordHash: String) -> User {
			.init(email: email,
				  passwordHash: passwordHash,
				  subscriptionStatus: subscriptionStatus,
				  role: role,
				  subscriptionPlanID: subscriptionPlanID
			)
		}
	}
}

extension User {
	struct UpdateInput: Content {
		var email: String?
		var subscriptionStatus: SubscriptionStatus?
		var subscriptionPlanID: SubscriptionPlan.IDValue?

		/// Updates the given `User` model by applying all non-nil fields from this `UpdateInput`.
		///
		/// Only the values that are not nil will overwrite the corresponding fields in the existing model.
		/// This allows for partial updates.
		///
		/// - Parameters:
		///   - user: The existing `User` model to be updated.
		///   - db: A database reference (not currently used in this function).
		/// - Returns: The updated `User` model.
		func update(_ user: User) -> User {
			let updatedUser = user

			applyIfPresent(email) { updatedUser.email = $0 }
			applyIfPresent(subscriptionStatus) { updatedUser.subscriptionStatus = $0 }
			applyIfPresent(subscriptionPlanID) { updatedUser.$subscriptionPlan.id = $0 }

			return updatedUser
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

	struct UpdatePasswordInput: Content {
		var password: String?

		/// Updates the given `User` model by applying all non-nil fields from this `UpdatePasswordInput`.
		///
		/// Only the values that are not nil will overwrite the corresponding fields in the existing model.
		/// This allows for partial updates.
		///
		/// - Parameters:
		///   - user: The existing `User` model to be updated.
		///   - db: A database reference (not currently used in this function).
		/// - Returns: The updated `User` model.
		func update(_ user: User, passwordHash: String) -> User {
			let updatedUser = user

			updatedUser.passwordHash = passwordHash

			return updatedUser
		}
	}
}

extension User {
	struct PublicOutput: Content {
		let id: UUID
		let email: String
		let subscriptionStatus: SubscriptionStatus
		let role: Role
		let subscriptionPlanID: SubscriptionPlan.IDValue
	}
}
