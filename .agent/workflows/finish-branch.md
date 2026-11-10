---
description: Finish Branch — Finalização de Branch
---
# Finish Branch — Finalização de Branch

Finalize o trabalho na branch de desenvolvimento atual.

## Processo

### 1. Verificação Final
- Rode TODOS os testes do projeto
- Confirme que todos passam
- Verifique se não há arquivos não commitados (`git status`)
- Revise os commits da branch (`git log --oneline main..HEAD`)

### 2. Apresente Opções

**"Trabalho na branch concluído. Todos os testes passando. Opções:"**

1. **Merge direto** → Merge na branch principal
2. **Criar PR** → Crie uma Pull Request para review
3. **Manter branch** → Deixar a branch aberta para mais trabalho
4. **Descartar** → Deletar a branch (se foi apenas exploratório)

### 3. Execute a Escolha

**Se Merge:**
```bash
git checkout main
git merge --no-ff <branch-name>
git push
```

**Se PR:**
```bash
git push -u origin <branch-name>
# Crie o PR via gh cli ou instrua o usuário
gh pr create --title "feat: <descrição>" --body "## Mudanças\n<resumo>"
```

**Se Manter:**
- Apenas confirme o status atual

**Se Descartar:**
- Confirme com o usuário antes de deletar
```bash
git checkout main
git branch -D <branch-name>
```

### 4. Limpeza
- Remova arquivos temporários se houver
- Atualize documentação se necessário
