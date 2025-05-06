//
//  ScanJob.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 06/05/2025.
//

import Queues
import Vapor

struct ScanJob: AsyncScheduledJob {
	func run(context: QueueContext) async throws {
		let users = try await User.query(on: context.application.db).with(\.$subscriptionPlan).all()
		let now = Date()

		for user in users {
			let plan = try await user.$subscriptionPlan.get(on: context.application.db)

			// Get all scans for the user
			let scans = try await user.$scans.get(on: context.application.db)

			// Filter scans within the plan's frequency
			let recentScans = scans.filter { scan in
				guard let scanDate = scan.createdAt else { return false }
				switch plan.scanFrequency {
				case .daily:
					return Calendar.current.isDateInToday(scanDate)
				case .weekly:
					return Calendar.current.dateComponents([.day], from: scanDate, to: now).day ?? 0 < 7
				case .monthly:
					return Calendar.current.dateComponents([.month], from: scanDate, to: now).month ?? 0 < 1
				}
			}

			// Check quota
			if recentScans.count >= plan.maxUrls {
				context.logger.info("User \(user.id?.uuidString ?? "unknown") has reached their scan quota.")
				continue
			}

			// Scan each scan input if quota not reached
			for scan in scans {
				let shouldScan: Bool
				if let lastScan = scan.createdAt {
					switch plan.scanFrequency {
					case .daily:
						shouldScan = !Calendar.current.isDateInToday(lastScan)
					case .weekly:
						shouldScan = (Calendar.current.dateComponents([.day], from: lastScan, to: now).day ?? 0) >= 7
					case .monthly:
						shouldScan = (Calendar.current.dateComponents([.month], from: lastScan, to: now).month ?? 0) >= 1
					}
				} else {
					shouldScan = true
				}

				if shouldScan {
					let req = Request(application: context.application, on: context.eventLoop)
					try await ScanController.handleScan(scan.input, with: scan, on: req)
				}
			}
		}

		context.logger.info("ScanJob executed with success.")
	}
}
