//
//  SubscriptionPlan+Ext.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 06/05/2025.
//

import Foundation

extension SubscriptionPlan {
	enum Name: String, Codable {
		case free, starter, pro, team
	}

	enum ScanFrequency: String, Codable {
		case daily, weekly, monthly
	}
}
