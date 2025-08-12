import XCTest
import CoreData
@testable import Jarvis

final class ImportValidationTests: XCTestCase {
    func testImportDedup() throws {
        let p = PersistenceController(inMemory: true)
        let ctx = p.container.viewContext

        let listId = UUID()
        let env = BackupEnvelope(
            version: 1,
            lists: [.init(id: listId, name: "L", icon: nil, color: nil, isSystem: false, createdAt: Date(), updatedAt: Date())],
            tasks: [], steps: [], tags: []
        )
        try DataBackupService.importEnvelope(env)
        try DataBackupService.importEnvelope(env) // re-import

        let req = CDList.fetchRequest(); req.predicate = NSPredicate(format: "id == %@", listId as CVarArg)
        let count = try ctx.count(for: req)
        XCTAssertEqual(count, 1)
    }

    func testImportEmptyFileFails() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("empty.json")
        try? Data().write(to: tmp)
        XCTAssertThrowsError(try DataBackupService.import(from: tmp))
    }

    func testImportInvalidSchemaFails() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("invalid.json")
        try "{}".data(using: .utf8)!.write(to: tmp)
        XCTAssertThrowsError(try DataBackupService.import(from: tmp))
    }

    func testDuplicateIdsInEnvelopeFailsValidation() throws {
        let id = UUID()
        let env = BackupEnvelope(version: 1,
                                 lists: [.init(id: id, name: "L1", icon: nil, color: nil, isSystem: false, createdAt: Date(), updatedAt: Date()), .init(id: id, name: "L2", icon: nil, color: nil, isSystem: false, createdAt: Date(), updatedAt: Date())],
                                 tasks: [], steps: [], tags: [])
        XCTAssertThrowsError(try DataBackupService.importEnvelope(env))
    }
}


