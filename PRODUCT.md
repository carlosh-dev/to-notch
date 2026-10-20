# Product

<!-- impeccable:product-schema 1 -->

## Platform

macos

App nativo de macOS (SwiftUI + AppKit, macOS 14+). Não se encaixa em web/ios/android/adaptive: a referência são as convenções do Mac (menu bar, notch, painéis não-ativantes), não iOS nem web.

## Users
Devs e usuários de Mac com MacBook de notch que querem uma lista de tarefas leve, sempre à mão, mas nunca no caminho. Instalam pelo GitHub (`install.sh`) ou por `.dmg`.

## Product Purpose
Uma lista de tarefas que vive no notch do MacBook. Passar o mouse mostra a próxima pendente, clicar abre a lista completa e tirar o mouse recolhe. Sucesso é anotar e marcar tarefas sem sair do app em uso, e ver de relance quanto do dia já foi feito.

## Positioning
Dois pilares com o mesmo peso:
- **Invisível até precisar:** sem ícone no Dock nem janela, vive no notch, aparece no hover e some sozinho. Captura sem atrito.
- **Progresso sempre visível:** uma barra fina sob o notch mostra a fração de tarefas concluídas, mesmo com o painel recolhido.

## Operating Context
- Fica sempre rodando; abre com o sistema quando instalado como `.app`.
- Usado em momentos rápidos no meio de outro trabalho: o painel é não-ativante e devolve o teclado ao app anterior quando recolhe.
- Em telas sem notch (monitor externo), usa uma faixa de 200pt no centro da barra de menus.
- Dados em `~/Library/Application Support/to-notch/todos.json`; preferências em UserDefaults.

## Capabilities and Constraints
- Adicionar, marcar, remover, editar (título + descrição) e reordenar tarefas arrastando.
- Configurações no próprio painel: cor da barra de progresso (paleta fixa + RGB animado), abrir ao iniciar, limpar concluídas, apagar todas, sair.
- **Lista simples:** sem datas, prioridades, tags ou sincronização. Continua sendo uma lista curta.
- **Sem dependências:** só SwiftUI/AppKit, nenhum pacote externo.
- **Leve em CPU/bateria:** fica sempre rodando; nada de trabalho pesado em segundo plano. Animações contínuas (como a barra RGB) são exceção e precisam ser baratas.
- Modais, alerts e NSColorPanel abrem fora do painel e são cortados pelo hover-collapse. Interações ficam inline.
- Os textos da interface hoje estão em pt-BR; suporte a outros idiomas está em aberto.
- Assinatura ad-hoc por padrão; Developer ID + notarização é opcional (`install.sh dmg`).

## Brand Commitments
- Nome: **to-notch** (minúsculo).
- Assets: `assets/logo.svg`, `assets/AppIcon.icns`.

## Evidence on Hand
O README.md descreve as funcionalidades e a instalação. Não há depoimentos, métricas de uso nem imprensa; não inventar.

## Product Principles
1. O notch é a casa: tudo acontece dentro do painel, nada em janelas separadas.
2. Fora do caminho por padrão: o que rouba foco, prende o painel aberto ou pede atenção precisa de um motivo forte.
3. Lista curta em vez de lista poderosa: recusar funcionalidades que a transformem num gerenciador de tarefas.
4. App em segundo plano paga aluguel em CPU: todo efeito sempre ligado precisa justificar o custo.
