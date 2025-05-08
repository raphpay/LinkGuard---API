//
//  EmailService.swift
//  linkguard-api
//
//  Created by Raphaël Payet on 08/05/2025.
//

import Fluent
import Vapor
import Smtp

struct EmailService {
	static func generateEmailReport(for scans: [Scan], user: User, on database: any Database) async throws -> String {
		var inaccessibleScans = [Scan]()
		for scan in scans {
			if let linkResult = try await scan.$linkResult.get(on: database) {
				if !linkResult.isAccessible {
					inaccessibleScans.append(scan)
				}
			}
		}

		return """
		<h2>Rapport de scan pour \(user.email)</h2>
		<p>Total des scans : \(scans.count)</p>
		<p>Inaccessibles : \(inaccessibleScans.count)</p>
		<ul>
		\(inaccessibleScans.map { "<li>\($0.input)</li>" }.joined(separator: "\n"))
		</ul>
		"""
	}

	static func generateEmailReportForSingleScan(_ scan: Scan, email: String, on database: any Database) async throws -> String {
		var htmlReport = """
		<h2>Rapport de scan pour \(email)</h2>
		<p>URL scanné : \(scan.input)</p>
		"""

		guard let linkResult = try await scan.$linkResult.get(on: database) else {
			throw Abort(.notFound, reason: "notFound.linkResult")
		}

		if linkResult.isAccessible {
			htmlReport += """
			<p>L'URL scanné est accessible !</p>
			<ul>
			</ul>
			"""
		} else {
			htmlReport += """
			<p>L'URL scanné est inaccessible !</p>
			<ul>
			</ul>
			"""
		}

		return htmlReport
	}

	static func sendEmailReport(to email: String, with content: String, on req: Request) async throws {
		guard let sender = Environment.get("BREVO_SENDER") else {
			throw Abort(.internalServerError, reason: "Missing Brevo credentials")
		}

		let emailObject = try Email(
			from: EmailAddress(address: sender, name: "LinkGuard"),
			to: [EmailAddress(address: email)],
			subject: "Votre rapport de scan LinkGuard",
			body: content,
			isBodyHtml: true
		)

		try await req.application.smtp.send(emailObject)
	}
}
