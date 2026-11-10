---
description: Configuração inicial do projeto e preenchimento de templates (Uso único)
---

# Configuração Inicial de Novo Projeto

> [!CAUTION]
> **INSTRUÇÃO PARA O AGENTE DE IA:**
> Este é um workflow de **USO ÚNICO** de scaffolding. O seu objetivo é entrevistar o usuário para captar a essência do sistema e preencher os templates vazios na pasta `_docs`.
> **MANDATÓRIO:** No final da execução com sucesso, você será instruído a **DELETAR ESTE ARQUIVO** (`.agent/workflows/configurar.md`).

## Passo 1: Entrevista com o Usuário
O primeiro passo ao rodar o comando `/configurar` é fazer as seguintes perguntas ao usuário (de preferência todas juntas de forma clara):

1. **Nome do Projeto:** Qual o nome formal deste novo projeto?
2. **Contexto e Objetivo:** Você possui algum documento bruto com a ideia? Se não possuir, pode me explicar brevemente o que é o sistema, que problema resolve e quem são os atores principais?
3. **Pilha Tecnológica (Stack):** Quais linguagens, frameworks ou bancos de dados você pretende adotar?
4. **Aesthetics & Restrições (Opcional):** Existe alguma preferência de design (ex: Dark Mode, Minimalista) ou restrições de código (ex: "Vanilla JS apenas", "sem frameworks de backend")?

*Aguarde o usuário responder a essas perguntas antes de continuar.*

## Passo 2: Processamento e Preenchimento dos Templates
Após compreender as respostas do usuário, utilize suas ferramentas adequadas para **substituir todos os placeholders** (geralmente marcados com colchetes como `[NOME DO PROJETO]`) nos seguintes arquivos da pasta `_docs/`:

1. **`CONTEXTO.md`**: 
   - Nomeie o projeto no topo.
   - Preencha "O que é", "Motivação", e "Fluxo Principal".
   - Defina o "Status Atual" como a data de hoje e a fase como "Setup Inicial".
   - Preencha as seções da "Stack" e "Design" com base nas respostas.

2. **`CHANGELOG.md`**:
   - Substitua o título do projeto.
   - (Opcional) Crie o primeiro release bloqueado de Setup, ex: `[0.1.0] - Inicialização do Repositório`.

3. **`MEMORIA.md`**:
   - Substitua o título do projeto.
   - Insira uma seção "Sessão 1 - Setup" descrevendo as regras e visão geral que o usuário acabou de te contar neste chat.

## Passo 3: Auto-Destruição
Após preencher a documentação e ter certeza de que o `/contexto` do projeto agora existe formalmente:

1. Informe ao usuário algo semelhante a: *"Os documentos de template em `_docs` foram preenchidos com o escopo que você passou."*
2. Como este workflow é de configuração primária e não deve poluir a aba de comandos diários, execute um terminal para **excluir este próprio arquivo**.
   **Comando sugerido:** `rm .agent/workflows/configurar.md`
