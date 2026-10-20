#!/bin/sh
# Compila e empacota to-notch.app.
#   ./install.sh       instala em /Applications e abre
#   ./install.sh dmg   gera .build/to-notch.dmg para distribuir
# Opcional (distribuição): SIGN_ID="Developer ID Application: Nome (TEAMID)" assina com hardened runtime;
# NOTARY_PROFILE=<perfil do `xcrun notarytool store-credentials`> notariza o .dmg.
set -e
cd "$(dirname "$0")"

swift build -c release
APP=.build/to-notch.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/to-notch "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"
cp assets/AppIcon.icns "$APP/Contents/Resources/"
if [ -n "$SIGN_ID" ]; then
    codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$APP"
else
    codesign --force --sign - "$APP" # assinatura ad-hoc, suficiente para uso local
fi

if [ "$1" = dmg ]; then
    DMG=.build/to-notch.dmg
    STAGE=.build/dmg
    rm -rf "$STAGE" "$DMG"
    mkdir -p "$STAGE"
    cp -R "$APP" "$STAGE/"
    ln -s /Applications "$STAGE/Applications" # atalho para arrastar o app
    hdiutil create -volname to-notch -srcfolder "$STAGE" -ov -format UDZO "$DMG"
    [ -n "$SIGN_ID" ] && codesign --sign "$SIGN_ID" --timestamp "$DMG"
    if [ -n "$NOTARY_PROFILE" ]; then
        xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
        xcrun stapler staple "$DMG"
    fi
    echo "Gerado $DMG"
    exit 0
fi

pkill -x to-notch || true
rm -rf /Applications/to-notch.app
cp -R "$APP" /Applications/
open /Applications/to-notch.app
echo "Instalado em /Applications/to-notch.app"
