// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "linkguard-api",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🌱 Fluent driver for Mongo.
        .package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
		.package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
		.package(url: "https://github.com/Mikroservices/Smtp.git", from: "3.0.0")
    ],
    targets: [
        .executableTarget(
            name: "linkguard-api",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentMongoDriver", package: "fluent-mongo-driver"),
				.product(name: "QueuesRedisDriver", package: "queues-redis-driver"),
				.product(name: "Smtp", package: "Smtp")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "linkguard-apiTests",
            dependencies: [
                .target(name: "linkguard-api"),
                .product(name: "VaporTesting", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
