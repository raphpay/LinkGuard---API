import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

	// 05/05/2025
	try app.register(collection: UserController())
	try app.register(collection: TokenController())
	try app.register(collection: ScanController())
}
