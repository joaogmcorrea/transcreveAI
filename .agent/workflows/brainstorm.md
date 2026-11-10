---
description: Brainstorm — Design Colaborativo
---
# Brainstorm — Design Colaborativo

Ajude a transformar ideias brutas em designs completos através de diálogo socrático.

## Processo

### 1. Entenda o Contexto
- Examine o estado atual do projeto (arquivos, docs, commits recentes)
- Entenda o que já existe antes de perguntar

### 2. Refine a Ideia (uma pergunta por vez)
- Faça UMA pergunta por mensagem
- Prefira perguntas de múltipla escolha quando possível
- Foque em entender: propósito, restrições, critérios de sucesso
- Se um tópico precisa de mais exploração, quebre em múltiplas perguntas

### 3. Explore Abordagens
- Proponha 2-3 abordagens diferentes com trade-offs
- Lidere com sua recomendação e explique o porquê
- Apresente opções de forma conversacional

### 4. Apresente o Design
- Quebre o design em seções de 200-300 palavras
- Pergunte após cada seção se está correto até agora
- Cubra: arquitetura, componentes, fluxo de dados, tratamento de erros, testes
- Volte atrás e clarifique se algo não faz sentido

### 5. Documente
- Salve o design validado em `docs/plans/YYYY-MM-DD-<topico>-design.md`
- Faça commit do documento

### 6. Próximos Passos
- Pergunte: "Pronto para configurar a implementação?"
- Se sim, use o workflow `/write-plan` para criar o plano detalhado

## Princípios
- **Uma pergunta por vez** — Não sobrecarregue
- **YAGNI implacável** — Remova features desnecessárias do design
- **Sempre explore alternativas** — 2-3 abordagens antes de decidir
- **Validação incremental** — Apresente o design em seções, valide cada uma
