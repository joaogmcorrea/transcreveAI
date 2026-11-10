---
description: Debug — Debugging Sistemático
---
# Debug — Debugging Sistemático

Processo de 4 fases para encontrar a causa raiz de bugs. NUNCA adivinhe — colete evidências primeiro.

## Fase 1: Coleta de Evidências

**ANTES de tocar em qualquer código:**

1. Reproduza o bug de forma consistente
2. Documente o comportamento esperado vs. observado
3. Identifique QUANDO começou (qual commit/mudança?)
4. Colete logs, stack traces, mensagens de erro

## Fase 2: Rastreamento de Componentes

Para CADA fronteira de componente:
- Logue o que ENTRA no componente
- Logue o que SAI do componente
- Verifique propagação de config/environment
- Verifique estado em cada camada

Rode UMA VEZ para coletar evidências mostrando ONDE quebra.
DEPOIS analise as evidências para identificar o componente que falha.
ENTÃO investigue esse componente específico.

## Fase 3: Formule e Teste Hipótese

1. Baseado nas evidências, formule UMA hipótese específica
2. Escreva um teste que PROVA a hipótese (teste que falha reproduzindo o bug)
3. Rode o teste — confirme que falha pelo motivo correto
4. Aplique o fix MÍNIMO
5. Rode o teste — confirme que passa
6. Rode TODOS os testes — confirme que nada mais quebrou

## Fase 4: Verificação e Defesa em Profundidade

1. O fix resolveu o bug original? Reproduza o cenário completo.
2. Adicione validação em múltiplas camadas (defense-in-depth)
3. Documente a causa raiz no commit message
4. Commit

## Fase 4.5: Quando Questionar a Arquitetura

Se 3+ fixes falharam:
- O problema pode ser arquitetural, não pontual
- Discuta com o usuário antes de tentar mais fixes
- Pergunte: "Devemos refatorar a arquitetura vs. continuar tratando sintomas?"

## Sinais de STOP — Volte à Fase 1

- Você está fazendo múltiplas mudanças simultâneas
- Você está adivinhando ao invés de seguindo evidências
- O fix "funciona" mas você não entende por quê
- Você está tentando fix parcial sem entender a causa raiz
- 95% dos casos "sem causa raiz" são investigação incompleta

## Racionalizações Bloqueadas

- "É simples, não precisa de processo" → Simples tem causa raiz também. Processo é rápido para bugs simples.
- "Vou só tentar trocar isso" → Guess-and-check é MAIS LENTO que debug sistemático.
- "É o primeiro bug" → Primeiro fix define o padrão. Faça certo.
- "Já sei o que é" → Ver sintomas ≠ entender causa raiz.
