import Foundation
import GRDB

class ConfigProfile: Record, Identifiable, ObservableObject {
    var id: Int64?
    @Published var name: String
    var order: UInt32
    var type: ProfileType
    var path: String
    @Published var remoteURL: String?
    @Published var autoUpdate: Bool
    var lastUpdated: Date?

    enum ProfileType: Int {
        case local = 0, icloud, remote
    }

    init(id: Int64? = nil, name: String, order: UInt32 = 0, type: ProfileType, path: String, remoteURL: String? = nil) {
        self.id = id
        self.name = name
        self.order = order
        self.type = type
        self.path = path
        self.remoteURL = remoteURL

        autoUpdate = false
        lastUpdated = nil
        if type == .remote {
            lastUpdated = Date()
        }
        super.init()
    }

    override class var databaseTableName: String {
        "profiles"
    }

    enum Columns: String, ColumnExpression {
        case id, name, order, type, path, remoteURL, autoUpdate, lastUpdated, userAgent
    }

    required init(row: Row) throws {
        id = row[Columns.id]
        name = row[Columns.name]
        order = row[Columns.order]
        type = ProfileType(rawValue: row[Columns.type])!
        path = row[Columns.path]
        remoteURL = row[Columns.remoteURL]
        autoUpdate = row[Columns.autoUpdate]
        lastUpdated = row[Columns.lastUpdated]
        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.order] = order
        container[Columns.type] = type.rawValue
        container[Columns.path] = path
        container[Columns.remoteURL] = remoteURL
        container[Columns.autoUpdate] = autoUpdate
        container[Columns.lastUpdated] = lastUpdated
    }

    override func didInsert(_ inserted: InsertionSuccess) {
        super.didInsert(inserted)
        id = inserted.rowID
    }

    func readContent() throws -> String {
        switch type {
        case .local, .remote:
            return try String(contentsOfFile: path)
        case .icloud:
            let saveURL = FilePath.iCloudDirectory.appendingPathComponent(path)
            saveURL.startAccessingSecurityScopedResource()
            defer {
                saveURL.stopAccessingSecurityScopedResource()
            }
            return try String(contentsOf: saveURL)
        }
    }

    func saveContent(_ content: String) throws {
        switch type {
        case .local, .remote:
            try content.write(toFile: path, atomically: true, encoding: .utf8)
        case .icloud:
            let saveURL = FilePath.iCloudDirectory.appendingPathComponent(path)
            saveURL.startAccessingSecurityScopedResource()
            defer {
                saveURL.stopAccessingSecurityScopedResource()
            }
            try content.write(to: saveURL, atomically: true, encoding: .utf8)
        }
    }
}
