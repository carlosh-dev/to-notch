import AppKit
import SwiftUI

let expandedSize = NSSize(width: 400, height: 320)
let barHeight: CGFloat = 2 // barra de progresso abaixo do notch

/// Retângulo do notch em coordenadas de tela. Sem notch (monitor externo), usa uma faixa de 200pt da menu bar.
func notchRect(screenFrame f: NSRect, leftWidth: CGFloat?, rightWidth: CGFloat?, topInset: CGFloat, menuBarHeight: CGFloat) -> NSRect {
    var width: CGFloat = 200, height = max(menuBarHeight, 24)
    if let l = leftWidth, let r = rightWidth, topInset > 0 {
        width = f.width - l - r
        height = topInset
    }
    return NSRect(x: f.midX - width / 2, y: f.maxY - height, width: width, height: height)
}

/// Painel expandido: mesmo topo e centro do notch, crescendo para baixo.
func expandedRect(around notch: NSRect, size: NSSize = expandedSize) -> NSRect {
    NSRect(x: notch.midX - size.width / 2, y: notch.maxY - size.height, width: size.width, height: size.height)
}

@MainActor @Observable
final class NotchState {
    enum Mode { case collapsed, peek, expanded }
    var mode = Mode.collapsed
    var notchHeight: CGFloat = 32
}

@MainActor
final class NotchPanel: NSPanel {
    private let state = NotchState()
    private var notch = NSRect.zero
    private var collapseTask: Task<Void, Never>?
    private var hoverArea: NSTrackingArea?

    init(store: TodoStore) {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .mainMenu + 3
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        isMovable = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

        // Tracking area num container simples, para não disputar com as do NSHostingView.
        let container = NSView()
        let host = NSHostingView(rootView: NotchView(store: store, state: state))
        host.sizingOptions = []
        host.autoresizingMask = [.width, .height]
        container.addSubview(host)
        let area = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        container.addTrackingArea(area)
        hoverArea = area
        contentView = container

        reposition()
        NotificationCenter.default.addObserver(
            self, selector: #selector(reposition), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    override var canBecomeKey: Bool { true } // TextField precisa receber teclado

    @objc func reposition() {
        guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main else { return }
        notch = notchRect(
            screenFrame: screen.frame,
            leftWidth: screen.auxiliaryTopLeftArea?.width,
            rightWidth: screen.auxiliaryTopRightArea?.width,
            topInset: screen.safeAreaInsets.top,
            menuBarHeight: screen.frame.maxY - screen.visibleFrame.maxY)
        state.notchHeight = notch.height
        setFrame(rect(for: state.mode), display: true)
    }

    private func rect(for mode: NotchState.Mode) -> NSRect {
        switch mode {
        case .collapsed: NSRect(x: notch.minX, y: notch.minY - barHeight, width: notch.width, height: notch.height + barHeight)
        case .peek: expandedRect(around: notch, size: NSSize(width: 360, height: notch.height + 36))
        case .expanded: expandedRect(around: notch)
        }
    }

    private func setMode(_ mode: NotchState.Mode) {
        guard state.mode != mode else { return }
        state.mode = mode
        setFrame(rect(for: mode), display: true, animate: true)
    }

    // Enter/exit de tracking areas internas (onHover, TextField, scroller) sobem pela cadeia de responders
    // até o painel; só a nossa área conta, senão sair da alça fecha o painel com o mouse em cima.
    override func mouseEntered(with event: NSEvent) {
        guard event.trackingArea === hoverArea else { return }
        collapseTask?.cancel()
        if state.mode == .collapsed { setMode(.peek) }
    }

    // Clique no notch/peek abre a lista completa; o evento não segue para não roubar o teclado.
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown, state.mode != .expanded {
            setMode(.expanded)
            return
        }
        // Painel não-key descarta o 1º clique (só o usa para virar key) e o botão não dispara.
        if event.type == .leftMouseDown, !isKeyWindow { makeKey() }
        super.sendEvent(event)
    }

    override func mouseExited(with event: NSEvent) {
        guard event.trackingArea === hoverArea else { return }
        // Pequeno atraso para não piscar quando o mouse passa raspando pela borda.
        collapseTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            self?.collapse()
        }
    }

    private func collapse() {
        makeFirstResponder(nil)
        setMode(.collapsed)
        if isKeyWindow { // devolve o teclado para o app que estava em uso
            orderOut(nil)
            orderFrontRegardless()
        }
    }
}
