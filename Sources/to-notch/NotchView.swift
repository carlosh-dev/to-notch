import SwiftUI

struct NotchView: View {
    let store: TodoStore
    let state: NotchState
    @State private var draft = ""
    @State private var dragging: Todo.ID?
    @State private var dragOffset: CGFloat = 0
    @State private var rowStep: CGFloat = 28
    @State private var editing: Todo?
    @State private var editTitle = ""
    @State private var editNotes = ""
    @State private var showSettings = false
    @AppStorage("barColor") private var barColor = "green"

    var body: some View {
        let radius: CGFloat = state.mode == .collapsed ? 10 : 20
        ZStack(alignment: .bottom) {
            Color.black
            switch state.mode {
            case .collapsed: EmptyView()
            case .peek: peek.transition(.opacity)
            case .expanded:
                if let todo = editing { editor(todo).transition(.opacity) }
                else if showSettings {
                    SettingsView(store: store) { showSettings = false }
                        .padding(.horizontal, 20)
                        .padding(.top, state.notchHeight + 8)
                        .padding(.bottom, 14)
                        .transition(.opacity)
                }
                else { content.transition(.opacity) }
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
                barFill.frame(width: geo.size.width * store.progress)
            }
        }
        .frame(height: barHeight)
    }

    @ViewBuilder private var barFill: some View {
        if barColor == "rgb" {
            // ponytail: redesenha a 30fps enquanto visível; baixar o intervalo se o consumo de CPU incomodar
            TimelineView(.animation(minimumInterval: 1 / 30)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate / 3
                LinearGradient(
                    colors: (0...6).map { Color(hue: (Double($0) / 6 + t).truncatingRemainder(dividingBy: 1), saturation: 1, brightness: 1) },
                    startPoint: .leading, endPoint: .trailing)
            }
        } else {
            barColors.first { $0.id == barColor }?.color ?? .green
        }
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
                    ForEach(store.todos) { draggableRow($0) }
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
                Button { showSettings = true } label: { Image(systemName: "gearshape") }
                    .buttonStyle(PanelIconButtonStyle())
                    .help("Configurações")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, state.notchHeight + 8)
        .padding(.bottom, 14)
    }

    // Arrasto em SwiftUI puro: o onMove da List depende de NSDraggingSession, que não inicia neste painel não-ativante.
    private func draggableRow(_ todo: Todo) -> some View {
        let isDragging = dragging == todo.id
        return row(todo)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { rowStep = $0 + 8 }
            .offset(y: shift(for: todo))
            .animation(.easeOut(duration: 0.15), value: shift(for: todo)) // só as vizinhas; a arrastada segue o mouse
            .offset(y: isDragging ? dragOffset : 0)
            .opacity(isDragging ? 0.7 : 1)
            .zIndex(isDragging ? 1 : 0)
    }

    // Só a alça inicia o arrasto. Espaço global: a alça se move junto com a linha, o local daria tremido.
    private func reorderGesture(_ todo: Todo) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .global)
                .onChanged {
                    dragging = todo.id
                    dragOffset = $0.translation.height
                }
                .onEnded { _ in
                    // Vizinhas já estão no lugar final; só a arrastada desliza até a vaga.
                    withAnimation(.easeOut(duration: 0.15)) {
                        if let i = store.todos.firstIndex(of: todo) {
                            let target = dropTarget(from: i)
                            store.move(from: [i], to: target > i ? target + 1 : target)
                        }
                        dragging = nil
                        dragOffset = 0
                    }
                }
    }

    // ponytail: passo = altura de uma linha; com títulos de várias linhas o alvo fica aproximado
    private func dropTarget(from i: Int) -> Int {
        max(0, min(store.todos.count - 1, i + Int((dragOffset / rowStep).rounded())))
    }

    /// Quanto uma linha vizinha se desloca para abrir espaço para a arrastada.
    private func shift(for todo: Todo) -> CGFloat {
        guard let id = dragging, id != todo.id,
              let from = store.todos.firstIndex(where: { $0.id == id }),
              let i = store.todos.firstIndex(of: todo) else { return 0 }
        let to = dropTarget(from: from)
        if from < i, i <= to { return -rowStep }
        if to <= i, i < from { return rowStep }
        return 0
    }

    private func row(_ todo: Todo) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
                .padding(4) // área de toque maior que o ícone
                .contentShape(Rectangle())
                .gesture(reorderGesture(todo))
                .onHover { $0 ? NSCursor.openHand.push() : NSCursor.pop() } // pointerStyle é macOS 15+
                .help("Arraste para reordenar")
            Button { store.toggle(todo) } label: {
                Image(systemName: todo.done ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.plain)
            Text(todo.title)
                .strikethrough(todo.done)
                .foregroundStyle(todo.done ? .secondary : .primary)
                .contentShape(Rectangle())
                .onTapGesture {
                    editTitle = todo.title
                    editNotes = todo.notes ?? ""
                    editing = todo
                }
            if todo.notes != nil {
                Image(systemName: "text.alignleft").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button { store.remove(todo) } label: { Image(systemName: "xmark") }
                .buttonStyle(PanelIconButtonStyle())
                .help("Remover")
        }
    }

    private func editor(_ todo: Todo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Título", text: $editTitle)
                .textFieldStyle(.plain)
                .font(.headline)
            TextEditor(text: $editNotes)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                .overlay(alignment: .topLeading) {
                    if editNotes.isEmpty {
                        Text("Descrição…").foregroundStyle(.tertiary).padding(.horizontal, 11).padding(.vertical, 6).allowsHitTesting(false)
                    }
                }
            HStack {
                Spacer()
                Button("Cancelar") { editing = nil }
                    .buttonStyle(PanelButtonStyle())
                    .keyboardShortcut(.cancelAction)
                Button("Salvar") {
                    store.update(todo, title: editTitle, notes: editNotes)
                    editing = nil
                }
                .buttonStyle(PanelButtonStyle(role: .prominent))
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, state.notchHeight + 8)
        .padding(.bottom, 14)
    }
}
