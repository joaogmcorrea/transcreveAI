#!/bin/bash
# Versionamento via git local: commit de tudo + tag anotada vX.Y.Z
# Uso: ./_docs/versionar.sh <X.Y.Z> ["mensagem opcional"]
# Exclusões: definidas no .gitignore da raiz do projeto.

set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Erro: Por favor, forneça o número da versão."
    echo "Uso: ./_docs/versionar.sh <X.Y.Z> [\"mensagem\"]"
    exit 1
fi

VERSION="${1#v}"
TAG="v$VERSION"
MESSAGE="${2:-release: $TAG}"

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Erro: versão inválida '$VERSION'. Use o formato X.Y.Z."
    exit 1
fi

# Sempre opera na raiz do projeto (pasta acima de _docs/)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Inicializa o repositório na primeira execução
if [ ! -d ".git" ]; then
    echo "Repositório git não encontrado. Inicializando em $ROOT_DIR..."
    git init -q
    git branch -M main 2>/dev/null || true
fi

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    echo "Erro: a versão $TAG já existe."
    exit 1
fi

echo "Iniciando versionamento para $TAG..."

git add -A

if git diff --cached --quiet; then
    echo "Nenhuma alteração para commitar. Criando a tag no commit atual."
else
    git commit -q -m "$MESSAGE"
fi

git tag -a "$TAG" -m "$MESSAGE"

echo "--------------------------------------------------------"
echo "Versão $TAG criada com sucesso."
echo "Commit: $(git rev-parse --short HEAD)"
echo "Para ver o histórico: git log --oneline --decorate"
echo "--------------------------------------------------------"
