---
description: Execute Plan — Execução do Plano
---
# Execute Plan — Execução do Plano

Execute o plano de implementação tarefa por tarefa, com verificação entre cada lote.

## Processo

### 1. Revise o Plano
- Leia o plano em `docs/plans/` completamente
- Identifique dependências, riscos, ambiguidades
- Se encontrar problemas críticos: PARE e reporte antes de executar
- Proponha batches de 3-5 tarefas que fazem sentido juntas

### 2. Apresente o Batch
- Liste as tarefas do batch atual
- Pergunte: "Posso executar este batch?"

### 3. Execute o Batch
Para cada tarefa no batch:
1. Anuncie qual tarefa está executando
2. Siga o ciclo TDD rigorosamente (RED → verify fail → GREEN → verify pass → REFACTOR → COMMIT)
3. Após o batch completo, mostre o output de verificação
4. Diga: "Batch concluído. Pronto para feedback."

### 4. Checkpoint
Com base no feedback:
- Aplique correções se necessário
- Execute o próximo batch
- Repita até completar

### 5. Finalização
Após todas as tarefas verificadas:
- Rode TODOS os testes do projeto
- Apresente resultado final
- Pergunte: "Quer fazer code review? Use `/code-review`"
- Ou finalize com `/finish-branch`

## Quando PARAR Imediatamente

- Bloqueio no meio do batch (dependência faltando, teste falha, instrução unclear)
- Plano tem gaps críticos
- Você não entende uma instrução
- Verificação falha repetidamente

**Pergunte ao invés de adivinhar. Não force através de bloqueios.**
