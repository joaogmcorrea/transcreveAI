---
description: Write Plan — Plano de Implementação
---
# Write Plan — Plano de Implementação

Crie um plano de implementação detalhado assumindo que o engenheiro tem ZERO contexto do codebase. Documente tudo: quais arquivos tocar, código completo, como testar. Tarefas granulares. DRY. YAGNI. TDD. Commits frequentes.

## Header Obrigatório do Plano

Todo plano DEVE começar com:

```markdown
# [Nome da Feature] — Plano de Implementação

**Objetivo:** [Uma frase descrevendo o que será construído]
**Arquitetura:** [2-3 frases sobre a abordagem]
**Stack:** [Tecnologias/bibliotecas principais]

---
```

## Granularidade: Tarefas de 2-5 Minutos

Cada passo é UMA ação:

- "Escrever o teste que falha" → passo
- "Rodar o teste e confirmar que falha" → passo
- "Implementar o código mínimo" → passo
- "Rodar os testes e confirmar que passam" → passo
- "Commit" → passo

## Estrutura de Cada Tarefa

```markdown
### Tarefa N: [Nome do Componente]

**Arquivos:**
- Criar: `caminho/exato/arquivo.py`
- Modificar: `caminho/exato/existente.py:123-145`
- Teste: `tests/caminho/exato/test_arquivo.py`

**Passo 1: Escrever o teste que falha**
[código completo do teste]

**Passo 2: Rodar teste e verificar que falha**
Comando: `pytest tests/path/test.py::test_name -v`
Esperado: FAIL com "function not defined"

**Passo 3: Implementar código mínimo**
[código completo da implementação]

**Passo 4: Rodar teste e verificar que passa**
Comando: `pytest tests/path/test.py::test_name -v`
Esperado: PASS

**Passo 5: Commit**
```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
```

## Regras do Plano

- Caminhos de arquivo EXATOS sempre
- Código COMPLETO no plano (nunca "adicione validação")
- Comandos EXATOS com output esperado
- DRY, YAGNI, TDD, commits frequentes

## Após Salvar o Plano

Salve em `docs/plans/YYYY-MM-DD-<feature>.md` e ofereça:

**"Plano salvo. Pronto para executar? Use `/execute-plan` para começar a implementação tarefa por tarefa."**
