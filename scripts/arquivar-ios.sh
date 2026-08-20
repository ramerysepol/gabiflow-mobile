#!/usr/bin/env bash
# Gera o IPA de loja e deixa o archive no Organizer do Xcode com o nome
# "GabiFlow" (o esquema do Flutter chama-se "Runner" e nao pode ser renomeado
# sem quebrar o build — entao renomeamos o archive depois de pronto).
#
# Uso (na raiz do gabiflow-mobile): ./scripts/arquivar-ios.sh
set -euo pipefail

VERSAO=$(grep '^version:' pubspec.yaml | awk '{print $2}')
DATA=$(date +%Y-%m-%d)
DESTINO="$HOME/Library/Developer/Xcode/Archives/$DATA/GabiFlow-$VERSAO.xcarchive"

echo "[1/3] flutter build ipa (release, ofuscado)..."
flutter build ipa --release --obfuscate --split-debug-info=build/symbols/ios | tail -2

echo "[2/3] Nomeando o archive como GabiFlow..."
mkdir -p "$(dirname "$DESTINO")"
rm -rf "$DESTINO"
cp -R build/ios/archive/Runner.xcarchive "$DESTINO"
plutil -replace Name -string "GabiFlow" "$DESTINO/Info.plist"

echo "[3/3] Pronto:"
echo "  Organizer: $DESTINO"
echo "  IPA direto (Transporter): build/ios/ipa/GabiFlow.ipa"
