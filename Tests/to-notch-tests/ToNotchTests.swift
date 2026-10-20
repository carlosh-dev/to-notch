import Foundation
import Testing
@testable import to_notch

@Test func notchGeometry() {
    // MacBook Air 13": 1470x956pt, notch de 170pt de largura e 32pt de altura.
    let screen = NSRect(x: 0, y: 0, width: 1470, height: 956)
    let notch = notchRect(screenFrame: screen, leftWidth: 650, rightWidth: 650, topInset: 32, menuBarHeight: 32)
    #expect(notch == NSRect(x: 650, y: 924, width: 170, height: 32))

    let expanded = expandedRect(around: notch, size: NSSize(width: 400, height: 320))
    #expect(expanded == NSRect(x: 535, y: 636, width: 400, height: 320))

    // Sem notch: faixa de 200pt centralizada no topo.
    let fallback = notchRect(screenFrame: screen, leftWidth: nil, rightWidth: nil, topInset: 0, menuBarHeight: 24)
    #expect(fallback == NSRect(x: 635, y: 932, width: 200, height: 24))
}

@MainActor @Test func storePersists() throws {
    let url = FileManager.default.temporaryDirectory.appending(path: "tonotch-\(UUID())/todos.json")
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

    let store = TodoStore(url: url)
    store.add("  comprar café ")
    store.add("   ") // ignorado
    store.add("revisar PR")
    #expect(store.progress == 0)
    #expect(store.firstPending?.title == "comprar café")
    store.toggle(store.todos[0])
    #expect(store.progress == 0.5)
    #expect(store.firstPending?.title == "revisar PR")
    store.move(from: [1], to: 0)
    #expect(store.todos.map(\.title) == ["revisar PR", "comprar café"])
    store.move(from: [0], to: 2)
    store.remove(store.todos[1])
    #expect(store.progress == 1)
    #expect(store.firstPending == nil)

    store.update(store.todos[0], title: "  ", notes: " moído fino ")
    #expect(store.todos[0].title == "comprar café")
    #expect(store.todos[0].notes == "moído fino")

    let reloaded = TodoStore(url: url)
    #expect(reloaded.todos.map(\.title) == ["comprar café"])
    #expect(reloaded.todos[0].done)
    #expect(reloaded.todos[0].notes == "moído fino")
}
