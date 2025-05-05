//
//  PasswordValidation.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Vapor

struct PasswordValidation {
	/// Validates the password based on the following criteria:
	/// - Parameters:
	///  - password: The password to validate.
	/// - Throws: An error if the password does not meet the criteria.
	/// - Checks:
	///   - Length: At least 8 characters.
	///   - Uppercase: At least one uppercase letter.
	///   - Digit: At least one digit.
	///   - Special Character: At least one special character.
	func validatePassword(_ password: String) throws {
		// Check the password length
		guard password.count >= 8 else {
			throw Abort(.unauthorized, reason: "unauthorized.password.invalidLength")
		}

		// Check an uppercase presence
		let uppercaseRegex = ".*[A-Z]+.*"
		let uppercasePredicate = NSPredicate { input, _ in
			guard let input = input as? String else {
				return false
			}
			return input.range(of: uppercaseRegex, options: .regularExpression) != nil
		}

		guard uppercasePredicate.evaluate(with: password) else {
			throw Abort(.unauthorized, reason: "unauthorized.password.missingUppercase")
		}

		// Check a digit presence
		let digitRegex = ".*[0-9]+.*"
		let digitPredicate = NSPredicate { input, _ in
			guard let input = input as? String else {
				return false
			}
			return input.range(of: digitRegex, options: .regularExpression) != nil
		}

		guard digitPredicate.evaluate(with: password) else {
			throw Abort(.unauthorized, reason: "unauthorized.password.missingDigit")
		}

		// Check a special character presence
		let specialCharRegex = ".*[!@#$%^&*()]+.*"
		let specialCharPredicate = NSPredicate { input, _ in
			guard let input = input as? String else {
				return false
			}
			return input.range(of: specialCharRegex, options: .regularExpression) != nil
		}

		guard specialCharPredicate.evaluate(with: password) else {
			throw Abort(.unauthorized, reason: "unauthorized.password.missingSpecialCharacter")
		}
	}

	/// Enumeration of possible validation errors.
	/// - invalidLength: The password is too short.
	/// - missingUppercase: The password is missing an uppercase letter.
	/// - missingDigit: The password is missing a digit.
	/// - missingSpecialCharacter: The password is missing a special character.
	enum ValidationError: Error {
		case invalidLength(String)
		case missingUppercase(String)
		case missingDigit(String)
		case missingSpecialCharacter(String)
	}
}
