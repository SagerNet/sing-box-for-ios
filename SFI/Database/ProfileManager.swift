import Foundation

import GRDB

class ProfileManager {
    private static var sharedManager: ProfileManager!

    static func shared() throws -> ProfileManager {
        if sharedManager == nil {
            sharedManager = try ProfileManager(databasePath: FilePath.sharedDirectory.relativePath + "/profiles.db")
        }
        return sharedManager
    }

    let database: any DatabaseWriter

    init(databasePath: String) throws {
        database = try DatabasePool(path: databasePath)
        try migrator.migrate(database)
    }

    func nextID() throws -> Int64 {
        try database.read { db in
            if let lastProfile = try ConfigProfile.all().order(Column("id").desc).fetchOne(db) {
                return lastProfile.id! + 1
            } else {
                return 1
            }
        }
    }

    func nextOrder() throws -> UInt32 {
        try database.read { db in
            try UInt32(ConfigProfile.fetchCount(db))
        }
    }

    func create(_ profile: ConfigProfile) throws {
        profile.order = try nextOrder()
        try database.write { db in
            try profile.insert(db, onConflict: .fail)
        }
    }

    func get(profileID: Int64) throws -> ConfigProfile? {
        try database.read { db in
            try ConfigProfile.fetchOne(db, id: profileID)
        }
    }

    func delete(_ profile: ConfigProfile) throws -> Bool {
        try database.write { db in
            try profile.delete(db)
        }
    }

    func delete(_ profileList: [ConfigProfile]) throws -> Int {
        try database.write { db in
            try ConfigProfile.deleteAll(db, keys: profileList.map {
                ["id": $0.id!]
            })
        }
    }

    func update(_ profile: ConfigProfile) throws -> Bool {
        try database.write { db in
            try profile.updateChanges(db)
        }
    }

    func update(_ profileList: [ConfigProfile]) throws {
        // TODO: batch update
        try database.write { db in
            for profile in profileList {
                try profile.updateChanges(db)
            }
        }
    }

    func list() throws -> [ConfigProfile] {
        try database.read { db in
            try ConfigProfile.all().order(Column("order").asc).fetchAll(db)
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createProfile") { db in
            try db.create(table: "profiles") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("order", .integer).notNull()
                t.column("path", .text).notNull()
            }
        }

        migrator.registerMigration("addProfileType") { db in
            try db.alter(table: "profiles") { t in
                t.add(column: "type", .integer).notNull().defaults(to: ConfigProfile.ProfileType.local.rawValue)
            }
        }

        return migrator
    }
}
