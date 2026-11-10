# Code Quality Standards

## Verificação Antes de Declarar Sucesso

ANTES de dizer que uma tarefa está completa:

1. Rode TODOS os testes do projeto (não apenas os novos)
2. Verifique que não há warnings ou erros no output
3. Confirme que a funcionalidade faz o que o plano pede
4. Verifique edge cases documentados no plano

## Padrões de Commit

- Commits atômicos: uma mudança lógica por commit
- Mensagens no formato: `tipo: descrição concisa`
  - `feat:` nova funcionalidade
  - `fix:` correção de bug
  - `test:` adição/modificação de testes
  - `refactor:` refatoração sem mudança de comportamento
  - `docs:` documentação

## Anti-Patterns a Evitar

- Código comentado (delete, o git tem histórico)
- Console.log / print de debug deixados no código
- Funções com mais de ~30 linhas
- Aninhamento profundo (> 3 níveis)
- Variáveis genéricas (data, temp, result, info)
- Catch vazio que engole erros silenciosamente
- TODO sem issue/ticket associado
