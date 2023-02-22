import Foundation

import GRDB

class ConfigProfile: Record, Identifiable, ObservableObject {
    var id: Int64?
    @Published var name: String
    var order: UInt32
    var path: String

    init(id: Int64? = nil, name: String, order: UInt32 = 0, path: String) {
        self.id = id
        self.name = name
        self.order = order
        self.path = path
        super.init()
    }

    override class var databaseTableName: String { "profiles" }

    enum Columns: String, ColumnExpression {
        case id, name, order, path
    }

    required init(row: Row) throws {
        id = row[Columns.id]
        name = row[Columns.name]
        order = row[Columns.order]
        path = row[Columns.path]
        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.order] = order
        container[Columns.path] = path
    }

    override func didInsert(_ inserted: InsertionSuccess) {
        super.didInsert(inserted)
        id = inserted.rowID
    }
}
