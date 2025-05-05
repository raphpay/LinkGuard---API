//
//  File.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent
import Vapor

extension User {
	struct Input: Content, Validatable {
		var email: String
		var password: String
		var frequency: Frequency


		static func validations(_ validations: inout Validations) {
			validations.add("frequency", as: Bool.self, is: .valid)
			validations.add("email", as: String.self, is: .email)
			validations.add("password", as: String.self, is: .count(8...))
		}
	}
}
