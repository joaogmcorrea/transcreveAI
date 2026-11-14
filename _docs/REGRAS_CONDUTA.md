# Regras de Conduta

Estas regras devem ser seguidas estritamente durante o desenvolvimento.

## 1. Confirmação de Solicitações
- **Solicitações Vagas:** Se uma solicitação não for especificada exatamente (ex: "remova a linha do quadrado branco"), **SEMPRE** confirme o que entendeu antes de executar.
- **Solicitações Objetivas:** Caso a solicitação seja especificada objetivamente (ex: "desative o border-bottom da classe .X"), pode prosseguir sem confirmação.

## 2. Relatório Final
- Ao final de cada trabalho, informe o que foi feito.
- Caso haja itens solicitados que não foram concluídos, liste-os em uma seção "O que não foi feito".
  - **Atenção:** Se não houver pendências de itens solicitados, **não** exiba a seção "O que não foi feito".

## 3. Versionamento Automático
- **Tarefa Completa:** Caso ao final da tarefa você tenha executado todos os pontos pedidos sem exceção, pergunte se pode executar o skill `versionamento` (commit + tag via `_docs/versionar.sh`).
- **Tarefa Incompleta:** Caso tenha ficado algum ponto sem fazer, **não** execute o versionamento.
- **Exceção para Documentação:** Em caso de tarefas de edição/adição de skills ou documentos .MD, **não** execute o versionamento.

## 4. Auto-Save de Conhecimento em MEMORIA.md
- **Durante a sessão:** Sempre que identificar uma descoberta, decisão, padrão ou aprendizado relevante para o projeto, registre **imediatamente** em `_docs/MEMORIA.md` — sem esperar o fim da sessão.
- **Critério de relevância:** Algo vale ser salvo se evitaria um erro futuro, documenta uma decisão não óbvia, ou captura um comportamento inesperado do sistema.
- **Marcação obrigatória:** Todo conhecimento salvo durante a sessão (antes do encerramento) deve ser marcado com a tag `⚠️ RASCUNHO — revisar ao final da sessão ou no início da próxima` logo abaixo do título da seção.
- **Revisão obrigatória:** No início de cada nova sessão (ou ao usar o skill `contexto`), revise os itens marcados como `RASCUNHO`:
  - Se o conhecimento ainda é válido: remova a tag e mantenha o conteúdo.
  - Se foi um teste ou experimento descartado: remova o bloco inteiro.
- **Não acumular rascunhos:** Ao encerrar formalmente uma sessão, tente limpar todas as tags `⚠️ RASCUNHO` antes de sair.

## 5. Regras Específicas do Projeto
- **App nativo:** Swift + SwiftUI, com AppKit só onde o SwiftUI não cobrir. Nada de Electron, webviews ou frameworks multiplataforma.
- **Processamento 100% local:** proibido enviar áudio ou texto para APIs ou serviços externos. Rede só para baixar modelos opcionais, com consentimento do usuário.
- **Velocidade é requisito:** o padrão de transcrição é sempre o modelo mais rápido medido no Mac ("Automático"). Qualquer mudança que deixe a transcrição mais lenta precisa ser justificada e aprovada.
- **UI mínima:** o painel principal mostra só a área de arrastar, o modelo, o idioma e os recentes. Opções novas vão para o menu "…" ou para Ajustes, nunca para a tela principal sem aprovação.
- **Mockup antes de tela nova:** mudanças visuais relevantes começam por um mockup aprovado pelo usuário.
- **Interface em pt-BR, inglês e espanhol** *(14/11/2026; antes, só pt-BR)*: o português é a língua de origem do catálogo de textos; todo texto novo visível no app ganha a tradução em inglês e em espanhol (pedido do owner, 11/11/2026).
- **Uso próprio, sem sandbox:** não cortar funções que dependem de Acessibilidade (atalho global, colar no app) para caber na App Store.
- **Chave das atualizações:** `_privado/chave-atualizacoes-ed25519.txt` nunca entra no git, em mensagens ou em logs. Sem ela, os apps instalados não aceitam versões novas. Toda release publicada tem número maior que a anterior, porque o Sparkle compara o `CFBundleVersion`.
