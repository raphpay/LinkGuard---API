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

	// Print routes ( dev only )
	// printRoutes(app)
}

func registerMigrations(_ app: Application) {
	// 05/05/2025
	app.migrations.add(CreateUser())
	app.migrations.add(CreateScan())
	app.migrations.add(CreateLinkResult())
	app.migrations.add(CreateToken())
}

// TO BE REMOVED
func printRoutes(_ app: Application) {
	print("Registered Routes:")
	for route in app.routes.all {
		let method = route.method.rawValue
		let path = route.path.map { $0.description }.joined(separator: "/")
		print("[\(method)] /\(path)")
	}
}
