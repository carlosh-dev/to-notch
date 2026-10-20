import SwiftUI

struct NotchView: View {
    let store: TodoStore
    let state: NotchState
    @State private var draft = ""

    var body: some View {
        let radius: CGFloat = state.mode == .collapsed ? 10 : 20
        ZStack(alignment: .bottom) {
            Color.black
            switch state.mode {
            case .collapsed: EmptyView()
            case .peek: peek.transition(.opacity)
            case .expanded: content.transition(.opacity)
            }
            if !store.todos.isEmpty { progressBar }
        }
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: radius, bottomTrailingRadius: radius))
        .animation(.easeOut(duration: 0.15), value: state.mode)
        .animation(.easeOut(duration: 0.3), value: store.progress)
        .environment(\.colorScheme, .dark)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.white.opacity(0.15)
                Color.green.frame(width: geo.size.width * store.progress)
            }
        }
        .frame(height: barHeight)
    }

    private var peek: some View {
        HStack(spacing: 8) {
            if let todo = store.firstPending {
                Image(systemName: "circle")
                Text(todo.title).lineLimit(1)
            } else {
                Text(store.todos.isEmpty ? "Nada pendente" : "Tudo feito ✓").foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, state.notchHeight)
        .padding(.bottom, barHeight)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if store.todos.isEmpty {
                        Text("Nada pendente").foregroundStyle(.secondary)
                    }
                    ForEach(store.todos) { row($0) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                TextField("Nova tarefa…", text: $draft)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        store.add(draft)
                        draft = ""
                    }
                Button { NSApp.terminate(nil) } label: { Image(systemName: "power") }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Sair")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, state.notchHeight + 8)
        .padding(.bottom, 14)
    }

    private func row(_ todo: Todo) -> some View {
        HStack {
            Button { store.toggle(todo) } label: {
                Image(systemName: todo.done ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.plain)
            Text(todo.title)
                .strikethrough(todo.done)
                .foregroundStyle(todo.done ? .secondary : .primary)
            Spacer()
            Button { store.remove(todo) } label: { Image(systemName: "xmark") }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Remover")
        }
    }
}
