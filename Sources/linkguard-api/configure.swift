import Vapor
import Fluent
import FluentMongoDriver
import Queues
import QueuesRedisDriver

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
	if Environment.get("APP_ENV") == "development" {
		printRoutes(app)
	}
}

func registerMigrations(_ app: Application) {
	// 05/05/2025
	app.migrations.add(CreateUser())
	app.migrations.add(CreateScan())
	app.migrations.add(CreateLinkResult())
	app.migrations.add(CreateToken())
	app.migrations.add(CreateSubscriptionPlan())
}

func registerJobs(_ app: Application) throws {
	// Redis configuration
	try app.queues.use(.redis(url: "redis://localhost:6379"))

	if Environment.get("APP_ENV") == "development" {
		app.queues.schedule(ScanJob())
			.minutely()
	} else {
		// Loading scheduled job
		app.queues.schedule(ScanJob())
			.daily()
			.at(10, 0)
	}

	// Start scheduled jobs
	try app.queues.startScheduledJobs()
}

// DEV ONLY
func printRoutes(_ app: Application) {
	print("Registered Routes:")
	for route in app.routes.all {
		let method = route.method.rawValue
		let path = route.path.map { $0.description }.joined(separator: "/")
		print("[\(method)] /\(path)")
	}
}
