import XCTest
import CoreData
@testable import Jarvis

final class SmartListFilterTests: XCTestCase {
    func testImportantFilter() throws {
        let p = PersistenceController(inMemory: true)
        let ctx = p.container.viewContext
        let list = CDList(context: ctx)
        list.id = UUID(); list.name = "L"; list.isSystem = false; list.createdAt = Date(); list.updatedAt = Date()
        for i in 0..<5 { let t = CDTask(context: ctx); t.id = UUID(); t.title = "T\(i)"; t.isCompleted = false; t.isImportant = (i % 2 == 0); t.createdAt = Date(); t.updatedAt = Date(); t.parentList = list }
        try ctx.save()

        let repo = TaskRepository(context: ctx)
        let important = try repo.important()
        XCTAssertTrue(important.allSatisfy { $0.isImportant && !$0.isCompleted })
    }

    func testMyDayFilter() throws {
        let p = PersistenceController(inMemory: true)
        let ctx = p.container.viewContext
        let list = CDList(context: ctx)
        list.id = UUID(); list.name = "L"; list.isSystem = false; list.createdAt = Date(); list.updatedAt = Date()
        let a = CDTask(context: ctx); a.id = UUID(); a.title = "A"; a.myDay = true; a.isCompleted = false; a.createdAt = Date(); a.updatedAt = Date(); a.parentList = list
        let b = CDTask(context: ctx); b.id = UUID(); b.title = "B"; b.myDay = false; b.isCompleted = false; b.createdAt = Date(); b.updatedAt = Date(); b.parentList = list
        try ctx.save()

        let repo = TaskRepository(context: ctx)
        let myday = try repo.myDay()
        XCTAssertTrue(myday.allSatisfy { $0.myDay && !$0.isCompleted })
    }

    func testPlannedFilter() throws {
        let p = PersistenceController(inMemory: true)
        let ctx = p.container.viewContext
        let list = CDList(context: ctx)
        list.id = UUID(); list.name = "L"; list.isSystem = false; list.createdAt = Date(); list.updatedAt = Date()
        let a = CDTask(context: ctx); a.id = UUID(); a.title = "A"; a.dueDate = Date().addingTimeInterval(3600); a.isCompleted = false; a.createdAt = Date(); a.updatedAt = Date(); a.parentList = list
        let b = CDTask(context: ctx); b.id = UUID(); b.title = "B"; b.reminder = Date().addingTimeInterval(7200); b.isCompleted = false; b.createdAt = Date(); b.updatedAt = Date(); b.parentList = list
        let c = CDTask(context: ctx); c.id = UUID(); c.title = "C"; c.isCompleted = false; c.createdAt = Date(); c.updatedAt = Date(); c.parentList = list
        try ctx.save()

        let repo = TaskRepository(context: ctx)
        let planned = try repo.planned()
        XCTAssertTrue(planned.allSatisfy { ($0.dueDate != nil || $0.reminder != nil) && !$0.isCompleted })
    }
}


