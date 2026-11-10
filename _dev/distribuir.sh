#!/bin/bash
# Gera o instalador do TranscreveAI para o GitHub Releases: compila em Release, monta o DMG (o app e um atalho
# para Aplicativos, para arrastar) e escreve o appcast.xml que o Sparkle do app lê para se atualizar.
# Mesma lógica do Cutline. O projeto do app é o de ../files.
#
# Uso:  ./_dev/distribuir.sh             → dist/TranscreveAI-<versão>.dmg, dist/appcast.xml e as cópias dist/appcast-<versão>.xml
#       ./_dev/distribuir.sh --publicar  → também cria a release v<versão> no GitHub com eles e a cópia TranscreveAI.dmg
#                                           (gh logado; as notas da release vêm de dist/notas-<versão>.md, se existir)
#
# Janela de atualização: dist/novidades-<versão>.<idioma>.md (pt-BR, en…), em Markdown e em tom de conversa, vão para o
# appcast; o Sparkle mostra a do idioma do Mac. As notas técnicas ficam na release, com o link no fim do texto.
#
# Contagem por versão: cada app procura atualização em appcast-<a versão dele>.xml (SUFeedURL do TranscreveAI-Info.plist).
# O GitHub conta os downloads de cada arquivo da release: dá quantos apps de cada versão procuram atualização, sem nada
# pessoal. Por isso toda release leva uma cópia do appcast para cada versão já lançada. Sem a cópia, os apps daquela
# versão param de receber atualizações.
#
# A versão é o MARKETING_VERSION do projeto. A chave privada EdDSA das atualizações nunca entra no repositório:
# TRANSCREVE_CHAVE_SPARKLE=/caminho/da/chave (padrão: ../_privado/chave-atualizacoes-ed25519.txt). Se houver no
# Acesso às Chaves um certificado de assinatura de código chamado "TranscreveAI" (ou o de TRANSCREVE_CERTIFICADO), o
# app é assinado com ele e o macOS não pede a permissão de Acessibilidade (anel de ações, colar no app) de novo a cada
# versão; sem ele, a assinatura é ad-hoc.
set -euo pipefail
cd "$(dirname "$0")"

REPOSITORIO=joaogmcorrea/transcreveAI
PROJETO=../files/TranscreveAI.xcodeproj
CHAVE=${TRANSCREVE_CHAVE_SPARKLE:-../_privado/chave-atualizacoes-ed25519.txt}
CERTIFICADO=${TRANSCREVE_CERTIFICADO:-TranscreveAI}
DERIVADOS=~/Library/Developer/Xcode/DerivedData/TranscreveAI-dist
SAIDA=dist

[ -f "$CHAVE" ] || { echo "Erro: a chave das atualizações não está em $CHAVE" >&2; exit 1; }

echo "Compilando (Release)…"
xcodebuild -project "$PROJETO" -scheme TranscreveAI -configuration Release \
    -derivedDataPath "$DERIVADOS" build -quiet
APP="$DERIVADOS/Build/Products/Release/TranscreveAI.app"
info() { /usr/libexec/PlistBuddy -c "Print :$1" "$APP/Contents/Info.plist"; }
VERSAO=$(info CFBundleShortVersionString)
BUILD=$(info CFBundleVersion)
MINIMO=$(info LSMinimumSystemVersion)

if security find-identity -v -p codesigning | grep -q "\"$CERTIFICADO\""; then
    echo "Assinando com o certificado \"$CERTIFICADO\"…"
    # De dentro para fora, como pede o Sparkle (sem --deep).
    SPARKLE="$APP/Contents/Frameworks/Sparkle.framework"
    for parte in "$SPARKLE"/Versions/B/XPCServices/*.xpc "$SPARKLE/Versions/B/Autoupdate" \
                 "$SPARKLE/Versions/B/Updater.app" "$SPARKLE" "$APP/Contents/Helpers/ffmpeg" "$APP"; do
        codesign --force --sign "$CERTIFICADO" --preserve-metadata=entitlements "$parte"
    done
else
    echo "Aviso: sem o certificado \"$CERTIFICADO\", o app vai com assinatura ad-hoc."
fi
codesign --verify --deep --strict "$APP"

mkdir -p "$SAIDA"
DMG="$SAIDA/TranscreveAI-$VERSAO.dmg"
echo "Montando $DMG…"
PASTA=$(mktemp -d)
trap 'rm -rf "$PASTA"' EXIT
ditto "$APP" "$PASTA/TranscreveAI.app"
ln -s /Applications "$PASTA/Applications"
hdiutil create -volname "TranscreveAI $VERSAO" -srcfolder "$PASTA" -fs HFS+ -format UDZO -ov "$DMG" -quiet

# sparkle:edSignature="…" length="…", conferidos pelo app (SUPublicEDKey) antes de abrir o DMG.
SIGN_UPDATE=$(find "$DERIVADOS/SourcePackages/artifacts" -path '*/bin/sign_update' -type f | head -1)
ASSINATURA=$("$SIGN_UPDATE" --ed-key-file "$CHAVE" "$DMG")

DESCRICOES=""
for NOVIDADES in "$SAIDA/novidades-$VERSAO".*.md; do
    [ -f "$NOVIDADES" ] || continue
    IDIOMA=$(basename "$NOVIDADES" .md)
    IDIOMA=${IDIOMA##*.}
    DESCRICOES+="      <description sparkle:format=\"markdown\" xml:lang=\"$IDIOMA\"><![CDATA[
$(cat "$NOVIDADES")
]]></description>
"
done

cat > "$SAIDA/appcast.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>TranscreveAI</title>
    <item>
      <title>TranscreveAI $VERSAO</title>
      <pubDate>$(LC_ALL=C date -R)</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSAO</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$MINIMO</sparkle:minimumSystemVersion>
      <sparkle:fullReleaseNotesLink>https://github.com/$REPOSITORIO/releases/tag/v$VERSAO</sparkle:fullReleaseNotesLink>
${DESCRICOES}      <enclosure url="https://github.com/$REPOSITORIO/releases/download/v$VERSAO/TranscreveAI-$VERSAO.dmg"
                 type="application/x-apple-diskimage" $ASSINATURA/>
    </item>
  </channel>
</rss>
EOF

# Uma cópia por versão já lançada (e a desta), para a contagem por versão.
rm -f "$SAIDA"/appcast-*.xml
COPIAS=()
for V in $( { gh release list --repo "$REPOSITORIO" --limit 1000 --json tagName --jq '.[].tagName | ltrimstr("v")' 2>/dev/null || true; echo "$VERSAO"; } | sort -u -V); do
    cp "$SAIDA/appcast.xml" "$SAIDA/appcast-$V.xml"
    COPIAS+=("$SAIDA/appcast-$V.xml")
done
echo "Pronto: $DMG, $SAIDA/appcast.xml e ${#COPIAS[@]} cópias por versão (versão $VERSAO)."

if [ "${1:-}" = "--publicar" ]; then
    NOTAS="$SAIDA/notas-$VERSAO.md"
    if [ -f "$NOTAS" ]; then NOTAS_ARG=(--notes-file "$NOTAS"); else NOTAS_ARG=(--generate-notes); fi
    # TranscreveAI.dmg (o mesmo arquivo, com nome fixo): releases/latest/download/TranscreveAI.dmg baixa sempre a mais nova.
    cp "$DMG" "$SAIDA/TranscreveAI.dmg"
    gh release create "v$VERSAO" "$DMG" "$SAIDA/TranscreveAI.dmg" "$SAIDA/appcast.xml" "${COPIAS[@]}" --repo "$REPOSITORIO" \
        --title "TranscreveAI $VERSAO" --verify-tag "${NOTAS_ARG[@]}"   # a tag v$VERSAO sobe com a main antes (skill versionamento)
else
    echo "Para publicar: crie a release v$VERSAO no GitHub com esses arquivos, ou rode ./_dev/distribuir.sh --publicar."
fi
