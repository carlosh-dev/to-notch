import ServiceManagement
import SwiftUI

let barColors: [(id: String, label: String, color: Color)] = [
    ("green", "Verde", .green), ("blue", "Azul", .blue), ("purple", "Roxo", .purple), ("pink", "Rosa", .pink),
    ("orange", "Laranja", .orange), ("yellow", "Amarelo", .yellow), ("white", "Branco", .white),
]

// Tudo inline: alert/NSColorPanel abririam fora do painel e o hover-collapse fecharia tudo.
struct SettingsView: View {
    let store: TodoStore
    let close: () -> Void
    @AppStorage("barColor") private var barColor = "green"
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var confirmDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Button(action: close) { Image(systemName: "chevron.left") }
                    .buttonStyle(PanelIconButtonStyle())
                    .keyboardShortcut(.cancelAction)
                    .help("Voltar")
                Text("Configurações").font(.headline)
            }
            section {
                row("Cor da barra") {
                    HStack(spacing: 4) {
                        ForEach(barColors, id: \.id) { swatch($0.id, label: $0.label, fill: $0.color) }
                        swatch("rgb", label: "RGB", fill: AngularGradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red], center: .center))
                    }
                }
                Divider()
                row("Abrir ao iniciar o Mac") {
                    Toggle("Abrir ao iniciar o Mac", isOn: $launchAtLogin)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .disabled(!Bundle.main.bundlePath.hasSuffix(".app")) // login item só existe rodando como .app
                        .onChange(of: launchAtLogin) { _, on in
                            do { try on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister() } catch {
                                NSLog("to-notch: falha ao alterar login item: \(error)")
                                launchAtLogin = SMAppService.mainApp.status == .enabled
                            }
                        }
                }
            }
            section {
                row("Concluídas", detail: "\(store.todos.count(where: \.done)) de \(store.todos.count)") {
                    Button("Limpar") { store.clearDone() }
                        .buttonStyle(PanelButtonStyle())
                        .disabled(!store.todos.contains(where: \.done))
                }
                Divider()
                row("Todas as tarefas") {
                    Button(confirmDelete ? "Apagar \(store.todos.count)?" : "Apagar") {
                        if confirmDelete { store.removeAll() }
                        confirmDelete.toggle()
                    }
                    .buttonStyle(PanelButtonStyle(role: confirmDelete ? .destructive : .normal))
                    .disabled(store.todos.isEmpty)
                }
            }
            Spacer(minLength: 0)
            Button { NSApp.terminate(nil) } label: { Label("Sair do to-notch", systemImage: "power") }
                .buttonStyle(PanelButtonStyle())
        }
        .animation(.easeOut(duration: 0.15), value: confirmDelete)
        .task(id: confirmDelete) { // confirmação expira sozinha
            guard confirmDelete else { return }
            try? await Task.sleep(for: .seconds(3))
            confirmDelete = false
        }
    }

    private func section(@ViewBuilder _ content: () -> some View) -> some View {
        VStack(spacing: 0) { content() }
            .padding(.horizontal, 12)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func row(_ title: String, detail: String? = nil, @ViewBuilder control: () -> some View) -> some View {
        HStack {
            Text(title)
            if let detail { Text(detail).foregroundStyle(.secondary).monospacedDigit() }
            Spacer()
            control()
        }
        .frame(minHeight: 36)
    }

    private func swatch(_ id: String, label: String, fill: some ShapeStyle) -> some View {
        let selected = barColor == id
        return Button { barColor = id } label: {
            Circle().fill(fill)
                .frame(width: 14, height: 14)
                .padding(3)
                .overlay(Circle().strokeBorder(.white.opacity(selected ? 0.9 : 0), lineWidth: 1.5))
                .frame(width: 22, height: 22)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Botão em cápsula que acende no hover; `prominent` é a ação principal, `destructive` pede confirmação.
struct PanelButtonStyle: ButtonStyle {
    enum Role { case normal, prominent, destructive }
    var role = Role.normal

    func makeBody(configuration: Configuration) -> some View { Styled(configuration: configuration, role: role) }

    private struct Styled: View {
        let configuration: Configuration
        let role: Role
        @State private var hovering = false
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.callout.weight(.medium))
                .foregroundStyle(role == .prominent ? Color.black : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(fill, in: Capsule())
                .opacity(isEnabled ? 1 : 0.35)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .contentShape(Capsule())
                .onHover { hovering = $0 }
                .animation(.easeOut(duration: 0.12), value: hovering)
                .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
        }

        private var fill: Color {
            let lift = (hovering && isEnabled ? 0.08 : 0) - (configuration.isPressed ? 0.06 : 0)
            return switch role {
            case .normal: .white.opacity(0.12 + lift)
            case .prominent: .white.opacity(0.9 + lift)
            case .destructive: .red.opacity(0.8 + lift)
            }
        }
    }
}

/// Ícone secundário que ganha destaque e um círculo de fundo no hover.
struct PanelIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Styled(configuration: configuration) }

    private struct Styled: View {
        let configuration: Configuration
        @State private var hovering = false

        var body: some View {
            configuration.label
                .frame(width: 22, height: 22)
                .foregroundStyle(hovering ? .primary : .secondary)
                .background(.white.opacity(configuration.isPressed ? 0.18 : hovering ? 0.1 : 0), in: Circle())
                .contentShape(Circle())
                .onHover { hovering = $0 }
                .animation(.easeOut(duration: 0.12), value: hovering)
        }
    }
}
