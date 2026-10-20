import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // sem ícone no Dock
let panel = NotchPanel(store: TodoStore())
panel.orderFrontRegardless()
app.run()
