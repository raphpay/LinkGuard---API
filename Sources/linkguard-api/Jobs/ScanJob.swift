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
		let users = try await User
			.query(on: context.application.db)
			.all()

		for user in users {
			if user.subscriptionStatus == .active {
				let scans = try await user.$scans.get(on: context.application.db)
//				let now = Date()

				for scan in scans {
					guard let lastScan = scan.lastScan else {
						// No last scan date, scan immediately
						let req = Request(application: context.application, on: context.eventLoop)
						try await ScanController.handleScan(scan.input, with: scan, on: req)
						continue
					}

//					let shouldScan: Bool
//					switch user.frequency {
//					case .daily:
//						shouldScan = Calendar.current.dateComponents([.day], from: lastScan, to: now).day ?? 0 >= 1
//					case .weekly:
//						shouldScan = Calendar.current.dateComponents([.day], from: lastScan, to: now).day ?? 0 >= 7
//					case .monthly:
//						shouldScan = Calendar.current.dateComponents([.month], from: lastScan, to: now).month ?? 0 >= 1
//					}

//					if shouldScan {
						let req = Request(application: context.application, on: context.eventLoop)
						try await ScanController.handleScan(scan.input, with: scan, on: req)
//					}
				}
			}
		}

		context.logger.info("ScanJob executed with success.")
	}
}
