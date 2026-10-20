import AppKit
import ServiceManagement

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // sem ícone no Dock

// Abrir com o sistema: só faz sentido rodando como .app (não via `swift run`).
// Registra só se nunca foi registrado, para respeitar quem desligar em Ajustes > Itens de Início.
if Bundle.main.bundlePath.hasSuffix(".app"), SMAppService.mainApp.status == .notRegistered {
    do { try SMAppService.mainApp.register() } catch { NSLog("to-notch: falha ao registrar login item: \(error)") }
}

let panel = NotchPanel(store: TodoStore())
panel.orderFrontRegardless()
app.run()
