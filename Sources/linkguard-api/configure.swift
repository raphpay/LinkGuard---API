import Vapor
import Fluent
import FluentMongoDriver
import Queues
import QueuesRedisDriver
import Smtp

// configures your application
public func configure(_ app: Application) async throws {
	// Configure MongoDB
	let dbURL = Environment.get("DATABASE_URL") ?? "mongodb://localhost:27017/linkguard"
	try app.databases.use(.mongo(connectionString: dbURL), as: .mongo)

	// register middlewares
	registerMiddlewares(app)

	// register migrations
	registerMigrations(app)

	// register routes
	try routes(app)

	// Print routes ( dev only )
	if Environment.get("APP_ENV") == "development" {
		printRoutes(app)
	}

  // register smtp connection ( brevo )
	registerSmtpConnection(app)
}

func registerMiddlewares(_ app: Application) {
	// uncomment to serve files from /Public folder
	// app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

	let corsConfiguration = CORSMiddleware.Configuration(
		allowedOrigin: .all,
		allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
		allowedHeaders: [
			.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin,
			"Access-Control-Allow-Origin", "fileName", "filePath", "Authorization", "Content-Type"
		],
		exposedHeaders: ["Content-Disposition"]
	)
	let cors = CORSMiddleware(configuration: corsConfiguration)
	// cors middleware should come before default error middleware using `at: .beginning`
	app.middleware.use(cors, at: .beginning)
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

func registerSmtpConnection(_ app: Application) {
	guard let hostname = Environment.get("BREVO_HOSTNAME"),
		  let port = Environment.get("BREVO_PORT"),
		  let username = Environment.get("BREVO_USERNAME"),
		  let password = Environment.get("BREVO_PASSWORD") else {
		app.logger.info("Unable to configure Brevo SMTP connection. Missing required environment variables.")
		return
	}
	app.smtp.configuration.hostname = hostname
	app.smtp.configuration.port = Int(port) ?? 567
	app.smtp.configuration.signInMethod = .credentials(username: username, password: password)
	app.smtp.configuration.secure = .startTls
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
