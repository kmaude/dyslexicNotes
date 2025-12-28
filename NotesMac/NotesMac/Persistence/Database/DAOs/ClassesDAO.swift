import Foundation
import GRDB

struct ClassesDAO {
    let db: DatabaseWriter

    func fetchAll() async throws -> [ClassModel] {
        try await db.read { db in
            try ClassModel.order(Column("is_system").desc, Column("name").asc).fetchAll(db)
        }
    }
}
