#!/bin/sh
# Compila, empacota to-notch.app, instala em /Applications e abre.
set -e
cd "$(dirname "$0")"

swift build -c release
APP=.build/to-notch.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/to-notch "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"
codesign --force --sign - "$APP" # assinatura ad-hoc, suficiente para uso local

pkill -x to-notch || true
rm -rf /Applications/to-notch.app
cp -R "$APP" /Applications/
open /Applications/to-notch.app
echo "Instalado em /Applications/to-notch.app"
