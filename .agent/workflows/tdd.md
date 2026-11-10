---
description: TDD — Ciclo Test-Driven Development
---
# TDD — Ciclo Test-Driven Development

Force o ciclo RED-GREEN-REFACTOR para a tarefa atual.

## O Ciclo

```
RED → Verify Fail → GREEN → Verify Pass → REFACTOR → Verify Still Pass → COMMIT → Next
```

### RED: Escreva o Teste
- UM teste mínimo mostrando o comportamento esperado
- Nome claro descrevendo o comportamento: `test_rejects_empty_email`
- Teste UMA coisa por teste

### Verify Fail
- Rode o teste
- Confirme que falha pelo motivo CORRETO
- Se não falha: o teste não está testando nada novo
- Se falha pelo motivo errado: reescreva o teste

### GREEN: Código Mínimo
- Escreva o código MÍNIMO para o teste passar
- Não otimize. Não generalize. Não antecipe.
- Apenas faça o teste passar.

### Verify Pass
- Rode o teste
- Confirme que passa
- Rode TODOS os testes para garantir que nada mais quebrou

### REFACTOR
- Limpe o código mantendo todos os testes passando
- Remova duplicação
- Melhore nomes
- Simplifique lógica
- Rode testes novamente após cada refatoração

### COMMIT
```bash
git add .
git commit -m "feat: <o que o teste prova que funciona>"
```

### Next
- Volte ao RED para o próximo comportamento

## Bom Teste vs. Mau Teste

**Bom:**
```python
def test_returns_empty_list_when_no_matches():
    result = search(items=["a", "b"], query="z")
    assert result == []
```

**Ruim:**
```python
def test_search():
    # Testa múltiplas coisas, nome genérico
    result = search(["a", "b", "c"], "a")
    assert len(result) == 1
    assert result[0] == "a"
    result2 = search([], "a")
    assert result2 == []
```
