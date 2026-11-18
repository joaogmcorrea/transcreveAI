#!/bin/bash
# Sobe o site para a Hostinger por SSH (rsync), sem senha: entra com a chave ~/.ssh/transcreveai_site,
# cadastrada no hPanel (Avançado › Acesso SSH). Passo a passo em _site/PUBLICAR.md.
#
#   ./_site/subir.sh                      monta o site (gerar.py) e mostra o que mudaria no servidor, sem enviar nada
#   ./_site/subir.sh --enviar             monta e envia de verdade
#   ./_site/subir.sh --sem-gerar [...]    usa o _site/dist/ que já existe, sem montar de novo
#
# O endereço do servidor fica em _privado/site-ssh.conf (fora do git), com quatro linhas:
#   SSH_HOST=<IP do hPanel>
#   SSH_PORT=65002
#   SSH_USER=<usuário do hPanel, u…>
#   PASTA=domains/joaocorrea.design/public_html/transcreveai
#
# Só manda o que mudou (compara pelo conteúdo) e apaga do servidor o que não existe mais no dist/. Por segurança, a
# PASTA precisa terminar em /transcreveai (a do Cutline fica ao lado, em public_html/cutline) e um envio apaga no
# máximo 20 arquivos. A pasta .well-known (certificados) nunca é tocada.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(dirname "$HERE")"
CONF="$RAIZ/_privado/site-ssh.conf"
CHAVE="$HOME/.ssh/transcreveai_site"
DIST="$HERE/dist"
SITE="https://transcreveai.joaocorrea.design"

enviar=0
gerar=1
for arg in "$@"; do
  case "$arg" in
    --enviar) enviar=1 ;;
    --sem-gerar) gerar=0 ;;
    -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "subir.sh: opção desconhecida: $arg (use --enviar, --sem-gerar ou --help)" >&2; exit 2 ;;
  esac
done

falha() { echo "subir.sh: $*" >&2; exit 1; }

[[ -f "$CHAVE" ]] || falha "falta a chave $CHAVE (veja _site/PUBLICAR.md, \"Subir pelo terminal\")."
[[ -f "$CONF" ]] || falha "falta $CONF, com SSH_HOST, SSH_PORT, SSH_USER e PASTA (veja o começo deste script)."

SSH_HOST="" SSH_PORT="" SSH_USER="" PASTA=""
# Lê só as quatro chaves (nunca executa o arquivo); linhas em branco e comentários ficam de fora.
while IFS='=' read -r chave valor || [[ -n "$chave" ]]; do
  valor="${valor%$'\r'}"; valor="${valor#\"}"; valor="${valor%\"}"
  case "$chave" in
    SSH_HOST) SSH_HOST="$valor" ;;
    SSH_PORT) SSH_PORT="$valor" ;;
    SSH_USER) SSH_USER="$valor" ;;
    PASTA) PASTA="$valor" ;;
  esac
done < "$CONF"
[[ -n "$SSH_HOST" && -n "$SSH_PORT" && -n "$SSH_USER" && -n "$PASTA" ]] \
  || falha "$CONF precisa de SSH_HOST, SSH_PORT, SSH_USER e PASTA."
[[ "$SSH_HOST" =~ ^[A-Za-z0-9.-]+$ && "$SSH_PORT" =~ ^[0-9]+$ && "$SSH_USER" =~ ^[A-Za-z0-9._-]+$ ]] \
  || falha "SSH_HOST, SSH_PORT ou SSH_USER com caracteres inesperados em $CONF."
PASTA="${PASTA%/}"
[[ "$PASTA" =~ ^[A-Za-z0-9._/-]+$ && "$PASTA" != *..* ]] || falha "PASTA com caracteres inesperados: $PASTA"
[[ "$(basename "$PASTA")" == "transcreveai" ]] \
  || falha "a PASTA precisa terminar em /transcreveai (para nunca apagar outro site): $PASTA"

# Sem senha nunca: BatchMode faz o ssh falhar em vez de pedir uma. Na primeira conexão, guarda a chave do servidor.
SSH=(ssh -i "$CHAVE" -p "$SSH_PORT" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=15
     -o StrictHostKeyChecking=accept-new)
DESTINO="$SSH_USER@$SSH_HOST"

if (( gerar )); then
  python3 "$HERE/gerar.py"
fi
[[ -f "$DIST/index.html" && -f "$DIST/pt/index.html" && -f "$DIST/es/index.html" ]] \
  || falha "o $DIST está incompleto; rode sem --sem-gerar."

echo "Conferindo a pasta no servidor ($DESTINO:$PASTA)…"
"${SSH[@]}" "$DESTINO" "test -d '$PASTA'" \
  || falha "não consegui entrar por SSH ou a pasta $PASTA não existe no servidor."

modo=(--dry-run)
(( enviar )) && modo=()
saida="$(mktemp)"
trap 'rm -f "$saida"' EXIT
echo
(( enviar )) && echo "Enviando:" || echo "Prévia (nada é enviado):"
rsync -rlptzc --delete-after --max-delete=20 --exclude .DS_Store --exclude .well-known \
  --itemize-changes ${modo[@]+"${modo[@]}"} -e "${SSH[*]}" "$DIST/" "$DESTINO:$PASTA/" > "$saida"
# O gerar.py reescreve todos os arquivos, então o rsync lista também os que só mudaram de data ('.f..t'): fica de
# fora o que não muda o site.
mudou="$(grep -E '^(<f|>f|cd|\*deleting)' "$saida" || true)"
if [[ -z "$mudou" ]]; then
  echo "  nada mudou: o servidor já tem esta versão."
else
  echo "$mudou" | sed -E 's/^[<>]f[^ ]* /  envia   /; s/^cd[^ ]* /  cria    /; s/^\*deleting +/  apaga   /'
fi

echo
if (( enviar )); then
  echo "Pronto: $SITE/ (e /pt/, /es/)."
  echo "As imagens ficam uma semana no cache do Cloudflare: se a de compartilhamento mudou, limpe o cache dela."
else
  echo "Para enviar de verdade: ./_site/subir.sh --enviar"
fi
