import XCTest
import CoreData
@testable import Jarvis

final class SearchTagTests: XCTestCase {
    func testSearchWithTagFilter() throws {
        let p = PersistenceController(inMemory: true)
        let ctx = p.container.viewContext
        let list = CDList(context: ctx)
        list.id = UUID(); list.name = "L"; list.isSystem = false; list.createdAt = Date(); list.updatedAt = Date()
        let a = CDTask(context: ctx); a.id = UUID(); a.title = "Alpha #work"; a.isCompleted = false; a.createdAt = Date(); a.updatedAt = Date(); a.parentList = list
        let b = CDTask(context: ctx); b.id = UUID(); b.title = "Beta #home";  b.isCompleted = false; b.createdAt = Date(); b.updatedAt = Date(); b.parentList = list
        try ctx.save()
        try TagRepository(context: ctx).setTags(for: a, names: ["work"])
        try TagRepository(context: ctx).setTags(for: b, names: ["home"])

        let results = try TaskRepository(context: ctx).search(keyword: "a", tag: "work")
        XCTAssertTrue(results.contains(where: { $0.title.contains("Alpha") }))
        XCTAssertFalse(results.contains(where: { $0.title.contains("Beta") }))
    }
}


