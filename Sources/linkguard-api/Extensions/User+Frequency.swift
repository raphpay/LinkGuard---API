//
//  User+Frequency.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 05/05/2025.
//

import Foundation

extension User {
	enum Frequency: String, Codable {
		case daily, weekly, monthly
	}
}
