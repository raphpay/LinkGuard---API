import Vapor

func routes(_ app: Application) throws {
    app.get { _ async in
        "It works!"
    }

    app.get("hello") { _ async -> String in
        "Hello, world!"
    }

	app.get("env") { _ async -> String in
		return Environment.get("APP_ENV") ?? "No .env"
	}

	// 05/05/2025
	try app.register(collection: UserController())
	try app.register(collection: TokenController())
	try app.register(collection: ScanController())
	try app.register(collection: SubscriptionPlanController())
}
