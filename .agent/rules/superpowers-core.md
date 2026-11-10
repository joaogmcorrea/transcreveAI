# Superpowers Core Rules

## Regra Fundamental

Antes de qualquer tarefa de desenvolvimento, SEMPRE verifique se existe um skill ou workflow relevante. Se houver 1% de chance de um skill se aplicar, USE-O.

## Fluxo Obrigatório

Quando alguém pedir para "construir X", "criar X", "implementar X":
1. **PRIMEIRO** use o workflow `/brainstorm` para refinar a ideia
2. **DEPOIS** use `/write-plan` para criar o plano de implementação
3. **SÓ ENTÃO** use `/execute-plan` para implementar

Quando alguém pedir para "corrigir bug", "debugar", "investigar erro":
1. **PRIMEIRO** use o workflow `/debug` para investigação sistemática
2. **NUNCA** tente adivinhar — colete evidências primeiro

## Princípios Inegociáveis

- **TDD sempre**: Escreva testes ANTES do código. Sem exceção.
- **YAGNI**: You Aren't Gonna Need It. Remova features desnecessárias.
- **DRY**: Don't Repeat Yourself.
- **Commits frequentes**: Commit após cada tarefa concluída.
- **Verificação antes de declarar sucesso**: Rode os testes. Veja o output. Confirme que funciona.

## Racionalizações Bloqueadas

O agente NÃO pode usar estas desculpas para pular o processo:

| Racionalização | Resposta |
|---|---|
| "É só uma pergunta simples" | Pode ser, mas verifique skills primeiro |
| "Preciso de mais contexto" | Leia o projeto primeiro, DEPOIS pergunte |
| "Deixa eu explorar primeiro" | Explorar SEM skill = desperdiçar contexto |
| "Isso parece produtivo" | Produtivo ≠ correto. Siga o processo |
| "É uma mudança pequena" | Mudanças pequenas quebram coisas. TDD. |
| "Já sei o que fazer" | Saber ≠ ter plano verificável. Planeje. |

## Padrão de Qualidade

- Nomes de variáveis e funções descritivos
- Documentação em docstrings/comentários quando necessário
- Tratamento de erros adequado
- Tipagem quando a linguagem suportar
- Testes com nomes que descrevem o comportamento esperado
