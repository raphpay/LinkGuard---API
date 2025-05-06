//
//  ScanDTO.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Fluent
import Vapor

extension Scan {
	struct Input: Content {
		let input: String
		let userID: User.IDValue

		func toModel() -> Scan {
			.init(input: input, email: nil, userID: userID)
		}
	}

	struct InputWithoutAccount: Content {
		let input: String
		let email: String

		func toModel() -> Scan {
			.init(input: input, email: email, userID: nil)
		}
	}
}

extension Scan {
	struct Output: Content {
		let id: UUID?
		let input: String
		let email: String?
		let userID: User.IDValue?
		let linkResult: LinkResult
	}
}
