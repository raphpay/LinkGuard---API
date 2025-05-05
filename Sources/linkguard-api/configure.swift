import Vapor
import Fluent
import FluentMongoDriver

// configures your application
public func configure(_ app: Application) async throws {
    // Configure MongoDB
    let dbURL = Environment.get("DATABASE_URL") ?? "mongodb://localhost:27017/linkguard"
    try app.databases.use(.mongo(connectionString: dbURL), as: .mongo)

    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

	// register migrations
	registerMigrations(app)

    // register routes
    try routes(app)
}

func registerMigrations(_ app: Application) {
	// 05/05/2025
	app.migrations.add(CreateUser())
	app.migrations.add(CreateScan())
	app.migrations.add(CreateLinkResult())
}
