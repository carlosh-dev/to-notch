import Foundation
import Observation
import SwiftUI // move(fromOffsets:toOffset:)

struct Todo: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var notes: String? // opcional: JSON antigo não tem a chave
    var done = false
}

@MainActor @Observable
final class TodoStore {
    private(set) var todos: [Todo] = []
    private let url: URL

    nonisolated static let defaultURL = URL.applicationSupportDirectory.appending(path: "to-notch/todos.json")

    init(url: URL = TodoStore.defaultURL) {
        self.url = url
        guard let data = try? Data(contentsOf: url) else { return }
        do {
            todos = try JSONDecoder().decode([Todo].self, from: data)
        } catch {
            // Não sobrescrever um arquivo ilegível no próximo save: guarda uma cópia.
            try? FileManager.default.moveItem(at: url, to: url.appendingPathExtension("corrupt"))
        }
    }

    var firstPending: Todo? { todos.first { !$0.done } }

    var progress: Double {
        todos.isEmpty ? 0 : Double(todos.count(where: \.done)) / Double(todos.count)
    }

    func add(_ title: String) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        todos.append(Todo(title: title))
        save()
    }

    func toggle(_ todo: Todo) {
        guard let i = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[i].done.toggle()
        save()
    }

    /// Título vazio mantém o anterior.
    func update(_ todo: Todo, title: String, notes: String) {
        guard let i = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty { todos[i].title = title }
        let notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        todos[i].notes = notes.isEmpty ? nil : notes
        save()
    }

    func remove(_ todo: Todo) {
        todos.removeAll { $0.id == todo.id }
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        todos.move(fromOffsets: source, toOffset: destination)
        save()
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(todos).write(to: url, options: .atomic)
        } catch {
            NSLog("to-notch: falha ao salvar todos: \(error)")
        }
    }
}
