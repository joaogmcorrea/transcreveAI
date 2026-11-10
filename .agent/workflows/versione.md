---
description: Regras de Versionamento
---
# Regras de Versionamento

> [!IMPORTANT]
> **SEMPRE** informe ao usuário quando for realizar o versionamento.

<!--
=========================================
🤖 SETUP INICIAL DE WORKFLOW (Apenas para a IA)
=========================================
INSTRUÇÃO PARA A IA: Ao executar este workflow pela PRIMEIRA VEZ neste projeto, você deve:
1. Obter o caminho ABSOLUTO da raiz deste projeto atual.
2. Atualizar o caminho do script `versionar.sh` no Bloco 1 abaixo para refletir "[caminho-absoluto-do-projeto]/_docs/versionar.sh".
3. APÓS FAZER ISSO, EXCLUA DEFINITIVAMENTE TODO ESTE BLOCO "🤖 SETUP INICIAL DE WORKFLOW" deste arquivo para que não seja exibido em futuras rodadas.
=========================================
-->

1. Executar `versionar.sh` (passando o número da versão como argumento)
   ```bash
   "./_docs/versionar.sh" <numero_da_versao>
   ```

2. Atualizar `_docs/CHANGELOG.md`:
   - Adicionar entrada com número da versão, data e lista de mudanças.

3. Atualizar `_docs/CONTEXTO.md`:
   - **Modificar:** Atualizar informações que não estão mais de acordo com a lógica do projeto (adicionando a data da modificação).
   - **Adicionar:** Novas informações relevantes (com data).
   - **Excluir:** Remover partes que não fazem mais sentido.

   > **IMPORTANTE:**
   > 1. Antes de **excluir** qualquer conteúdo do CONTEXTO.md, você deve **confirmar explicitamente** com o usuário.
   > 2. Ao editar, **informe ao usuário** o que foi modificado em bullet points resumidos.
   > 3. Marque as edições no arquivo com a data atual.

4. Atualizar `_docs/MEMORIA.md`:
   - Registrar descobertas, decisões e aprendizados da sessão.

5. Atualizar `_docs/SCRIPTS-LOGIC.md`:
   - Adicionar/atualizar arquivos de script criados ou alterados na sessão.
