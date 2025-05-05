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

    // register routes
    try routes(app)
}
