<p align="center">
  <img src="assets/logo.svg" width="128" alt="Logo do to-notch">
</p>

<h1 align="center">to-notch</h1>

<p align="center">Uma lista de tarefas que vive no notch do MacBook.</p>

## O que faz

- **Passe o mouse no notch** para ver a próxima tarefa pendente; **clique** para abrir a lista completa. Tire o mouse e ele se recolhe.
- **Adicione** tarefas no campo "Nova tarefa…" (Enter), **marque** como feita no círculo e **remova** no ×.
- **Clique no título** para editar o título e adicionar uma descrição.
- **Arraste pela alça** (☰) para reordenar, com prévia animada de onde a tarefa vai cair.
- Uma **barra de progresso verde** logo abaixo do notch mostra quanto já foi feito.
- Sem ícone no Dock e, instalado como app, **abre junto com o sistema**.
- Em telas sem notch (monitor externo), usa uma faixa no centro da barra de menus.

As tarefas ficam salvas em `~/Library/Application Support/to-notch/todos.json`.

## Requisitos

- macOS 14 (Sonoma) ou mais recente
- Swift 6 — Xcode ou as Command Line Tools (`xcode-select --install`)

## Instalação

```sh
git clone https://github.com/carlosh-dev/to-notch.git
cd to-notch
./install.sh
```

O `install.sh` compila em modo release, empacota o `to-notch.app` (assinatura ad-hoc, para uso local), instala em `/Applications` e abre o app. Rode de novo para atualizar.

Na primeira execução o app se registra como item de início. Para desligar: **Ajustes do Sistema › Geral › Itens de Início**.

### Via .dmg

```sh
./install.sh dmg   # gera .build/to-notch.dmg
```

Abra o `.dmg` e arraste o `to-notch` para **Aplicativos**.

No Mac onde foi gerado, abre direto. Em outro Mac, a assinatura ad-hoc faz o Gatekeeper bloquear: libere em **Ajustes do Sistema › Privacidade e Segurança › Abrir Mesmo Assim**, ou rode `xattr -dr com.apple.quarantine /Applications/to-notch.app`.

Para distribuir sem esse aviso é preciso um certificado Developer ID (Apple Developer Program) e notarização:

```sh
xcrun notarytool store-credentials to-notch   # uma vez: Apple ID, Team ID e senha de app
SIGN_ID="Developer ID Application: Seu Nome (TEAMID)" NOTARY_PROFILE=to-notch ./install.sh dmg
```

## Desenvolvimento

```sh
swift run    # roda direto, sem empacotar (não registra item de início)
swift test   # testes
```

## Desinstalar

```sh
pkill -x to-notch
rm -rf /Applications/to-notch.app
rm -rf ~/Library/Application\ Support/to-notch   # opcional: apaga as tarefas
```

Se ele continuar listado em Itens de Início, remova por lá.
