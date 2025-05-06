//
//  UserMiddleware.swift
//
//
//  Created by Raphaël Payet on 26/06/2024.
//

import Fluent
import Vapor

struct UserMiddleware {
	/// Validates the input data for creating a new user.
	///
	/// This method checks the following fields for validity:
	/// - `name` and `firstName` length (≤ 32 characters).
	/// - Optional `address` length (≤ 128 characters).
	/// - Validates the format of `mailAddress` (email format).
	/// - Checks if the `mailAddress` already exists in the database.
	/// - Ensures `conditionsAccepted` is true.
	/// - Validates the `conditionsAcceptedTimestamp` format (ISO 8601).
	///
	/// Throws a `.badRequest` error if any validation fails.
	///
	/// - Parameters:
	///   - userInput: The input data to validate.
	///   - database: The database connection for checking user availability.
	/// - Throws: A `.badRequest` error if any field is invalid.
	func validate(userInput: User.Input, on database: any Database) async throws {
		guard userInput.email.isValidEmail() else {
			throw Abort(.badRequest, reason: "badRequest.incorrectMailAddressFormat")
		}

		guard try await SubscriptionPlan.find(userInput.subscriptionPlanID, on: database) != nil else {
			throw Abort(.badRequest, reason: "badRequest.inexistantSubscriptionPlan")
		}

		try await checkUserAvailability(email: userInput.email, on: database)
	}

	/// Checks if a user with the given email address already exists in the database.
	///
	/// This method queries the database to check if any user already has the provided email address.
	///
	/// - Parameters:
	///   - mailAddress: The email address to check.
	///   - database: The database connection to query for user existence.
	/// - Throws: A `.badRequest` error if the user already exists.
	func checkUserAvailability(email: String, on database: any Database) async throws {
		let userCount = try await User
			.query(on: database)
			.filter(\.$email == email)
			.count()

		guard userCount == 0 else {
			throw Abort(.badRequest, reason: "badRequest.userAlreadyExists")
		}
	}
}

struct UserUpdateMiddleware {
	/// Validates the input data for updating an existing user.
	///
	/// This method performs validation on the following fields:
	/// - Basic information (`name`, `firstName`, `address`, `mailAddress`).
	/// - Conditions acceptance (`conditionsAccepted`, `conditionsAcceptedTimestamp`).
	///
	/// Throws a `.badRequest` error if any field is invalid.
	///
	/// - Parameters:
	///   - userInput: The input data to validate.
	///   - database: The database connection to use for validation.
	/// - Throws: An error if the input data is invalid.
	func validate(userInput: User.UpdateInput, on database: any Database) async throws {
		if let email = userInput.email {
			guard email.isValidEmail() else {
				throw Abort(.badRequest, reason: "badRequest.incorrectMailAddressFormat")
			}

			try await UserMiddleware().checkUserAvailability(email: email, on: database)
		}

		if let subscriptionPlanID = userInput.subscriptionPlanID {
			guard try await SubscriptionPlan.find(subscriptionPlanID, on: database) != nil else {
				throw Abort(.badRequest, reason: "badRequest.inexistantSubscriptionPlan")
			}
		}
	}
}

