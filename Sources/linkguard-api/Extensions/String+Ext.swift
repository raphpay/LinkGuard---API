//
//  String+Ext.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Foundation

/// A string extension that provides various utility functions for string manipulation and validation.
extension String {
	/// Check if a string is a valid ISO 8601 date format
	/// - Returns: A boolean indicating if the string is a valid ISO 8601 date format
	func isValidISOFormat() -> Bool {
		let dateFormatter = ISO8601DateFormatter()
		dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
		return dateFormatter.date(from: self) != nil
	}

	/// Convert a string to a date in ISO 8601 format
	/// - Returns: A date in ISO 8601 format if the string is a valid ISO 8601 date format, otherwise nil
	func ageFromISODate() -> Int? {
		let dateFormatter = ISO8601DateFormatter()
		dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
		guard let birthdate = dateFormatter.date(from: self) else { return nil }

		let calendar = Calendar.current
		let ageComponents = calendar.dateComponents([.year], from: birthdate, to: Date())
		return ageComponents.year
	}

	/// Check if a string is a valid email address
	/// - Returns: A boolean indicating if the string is a valid email address
	func isValidEmail() -> Bool {
		let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
		let isValid = NSPredicate { input, _ in
			guard let input = input as? String else {
				return false
			}

			return input.range(of: regex, options: .regularExpression) != nil
		}.evaluate(with: self)

		return isValid
	}

	/// Check if a string is a valid password
	/// - Returns: A boolean indicating if the string is a valid password
	func isValidPassword() -> Bool {
		let regex = "^(?=.*[0-9])(?=.*[!@#$%^&*(),.?\":{}|<>])[A-Za-z\\d!@#$%^&*(),.?\":{}|<>]{8,}$"
		let isValid = NSPredicate { input, _ in
			guard let input = input as? String else {
				return false
			}

			return input.range(of: regex, options: .regularExpression) != nil
		}.evaluate(with: self)

		return isValid
	}

	/// Generate a random password with a specified length
	/// - Parameter length: The length of the password to generate
	/// - Returns: A random password with the specified length
	/// - Note: The password contains at least one digit and one special character.
	///       The password is scrambled to ensure randomness.
	///       The default length is 8 characters.
	///       The password contains letters, digits, and special characters.
	func generatePassword(length: Int = 8) -> String {
		let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		let digits = "0123456789"
		let specialCharacters = "!@#$%^&*(),.?\":{}|<>"

		let randomDigit = digits.randomElement()!
		let randomSpecialCharacter = specialCharacters.randomElement()!

		let allCharacters = letters + digits + specialCharacters
		var password = String((0..<(length - 2)).compactMap { _ in allCharacters.randomElement() })

		password.append(randomDigit)
		password.append(randomSpecialCharacter)

		let shuffledPassword = password.scramble()

		return shuffledPassword
	}

	/// Scramble a string by randomly rearranging its characters
	/// - Returns: A scrambled version of the string
	/// - Note: The function uses arc4random_uniform to generate random indices for scrambling.
	///       The function creates a mutable array of characters from the string and randomly selects characters to build the scrambled string.
	func scramble() -> String {
		var chars = Array(self)
		var result = ""

		while !chars.isEmpty {
			let index = Int.random(in: 0..<chars.count)
			let char = chars.remove(at: index)
			result += String(char)
		}

		return result
	}

	/// Trim and lowercase a string
	/// - Returns: A trimmed and lowercased version of the string
	func trimAndLowercase() -> String {
		self.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
	}
}
