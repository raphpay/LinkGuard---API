//
//  ScanJob.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 06/05/2025.
//

import Queues
import Vapor
import Smtp

struct ScanJob: AsyncScheduledJob {
	func run(context: QueueContext) async throws {
		// Fetch all users
		let users = try await User.query(on: context.application.db).with(\.$subscriptionPlan).all()

		for user in users {
			let req = Request(application: context.application, on: context.eventLoop)
			// Fetch the plan of the user
			let plan = try await user.$subscriptionPlan.get(on: context.application.db)
			// Fetch the scans done by/for the user
			let scans = try await user.$scans.get(on: context.application.db)

			// Filter scans within the plan's frequency
			let recentScans = ScanController.filterRecentScans(with: scans, and: plan)

			// Check that the user is within the quota number
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

				let htmlContent = generateEmailReport(for: recentScans, user: user)
				try await sendEmailReport(to: user.email, user: user, with: htmlContent, on: req)
			}
		}

		context.logger.info("ScanJob executed with success.")
	}

	private func generateEmailReport(for scans: [Scan], user: User) -> String {
		let inaccessibleScans = scans.filter { $0.linkResult?.isAccessible == false }

		return """
		<h2>Rapport de scan pour \(user.email)</h2>
		<p>Total des scans : \(scans.count)</p>
		<p>Inaccessibles : \(inaccessibleScans.count)</p>
		<ul>
		\(inaccessibleScans.map { "<li>\($0.input)</li>" }.joined(separator: "\n"))
		</ul>
		"""
	}

	private func sendEmailReport(to email: String, user: User, with content: String, on req: Request) async throws {
		guard let sender = Environment.get("BREVO_SENDER") else {
			throw Abort(.internalServerError, reason: "Missing Brevo credentials")
		}

		let email = try Email(
			from: EmailAddress(address: sender, name: "LinkGuard"),
			to: [EmailAddress(address: email)],
			subject: "Votre rapport de scan LinkGuard",
			body: content,
			isBodyHtml: true
		)

		try await req.application.smtp.send(email)
	}
}
