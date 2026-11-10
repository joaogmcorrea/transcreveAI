# TDD Discipline

## Ciclo RED-GREEN-REFACTOR Obrigatório

Para TODA implementação de funcionalidade:

1. **RED** — Escreva UM teste mínimo mostrando o comportamento esperado
2. **Verifique que FALHA** — Rode o teste, confirme que falha pelo motivo correto
3. **GREEN** — Escreva o código MÍNIMO para o teste passar
4. **Verifique que PASSA** — Rode o teste, confirme que passa
5. **REFACTOR** — Limpe o código mantendo os testes passando
6. **COMMIT** — Faça commit da mudança

## Regras Absolutas

- NUNCA escreva código de produção antes do teste
- Se código foi escrito antes do teste: DELETE e recomece com TDD
- Testes que passam imediatamente NÃO provam nada — o teste deve FALHAR primeiro
- "Testar depois" ≠ TDD. Testes escritos depois são enviesados pela implementação
- Código difícil de testar = código difícil de usar. Ouça o teste.
- Teste manual NÃO substitui testes automatizados

## Racionalizações Bloqueadas

- "É simples demais para testar" → Código simples quebra. Teste leva 30 segundos.
- "Vou adaptar o código existente" → Isso é testar depois. Delete e comece com TDD.
- "Já testei manualmente" → Manual não prova edge cases. Automatize.
- "TDD é muito lento" → TDD é mais rápido que debugging. Pragmático = test-first.
- "Não dá pra deletar, já gastei tempo" → Sunk cost fallacy. Código não testado é dívida técnica.
