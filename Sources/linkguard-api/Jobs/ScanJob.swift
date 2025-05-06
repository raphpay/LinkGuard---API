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

		for user in users {
			let req = Request(application: context.application, on: context.eventLoop)
			let plan = try await user.$subscriptionPlan.get(on: context.application.db)
			let scans = try await user.$scans.get(on: context.application.db)

			// Filter scans within the plan's frequency
			let recentScans = ScanController.filterRecentScans(with: scans, and: plan)

			let canScan = try await ScanController.checkQuota(with: plan, and: recentScans, on: req)

			if canScan {
				// Scan each scan input if quota not reached
				for scan in recentScans {
					let shouldScan: Bool
					if let lastScan = scan.createdAt {
						switch plan.scanFrequency {
						case .daily:
							shouldScan = !Calendar.current.isDateInToday(lastScan)
						case .weekly:
							shouldScan = (Calendar.current.dateComponents([.day], from: lastScan, to: .now).day ?? 0) >= 7
						case .monthly:
							shouldScan = (Calendar.current.dateComponents([.month], from: lastScan, to: .now).month ?? 0) >= 1
						}
					} else {
						shouldScan = true
					}

					if shouldScan {
						_ = try await ScanController.handleScan(scan, on: req)
					}
				}
			}
		}

		context.logger.info("ScanJob executed with success.")
	}
}
