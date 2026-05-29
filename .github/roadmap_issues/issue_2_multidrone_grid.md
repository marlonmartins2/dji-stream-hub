# Issue #2: [Feature] Multi-Drone Dashboard Grid (Split-Screen Control Room) 🎛️

## 📝 Descrição / Description
Equipes profissionais de resgate, segurança, cobertura de eventos ou entusiastas de drones que operam mais de um drone ao mesmo tempo necessitam de uma central de monitoramento unificada. Atualmente, o DJI Stream Hub exibe apenas uma transmissão. Esta Issue propõe atualizar o layout da dashboard para permitir a exibição de até 4 transmissões simultâneas em formato de grade.

---

## 🛠️ Solução Proposta / Proposed Solution
- O MediaMTX suporta múltiplos caminhos de ingestão nativamente (ex: `live/drone1`, `live/drone2`, etc.).
- Atualizar a interface do `dashboard.html` adicionando um controle de visualização de grade no topo do player (Grid 1x1, Grid 1x2, Grid 2x2).
- Criar dinamicamente os players WebRTC com base nos caminhos de transmissão ativos ou permitir que o usuário digite os nomes dos fluxos extras.
- Implementar botões individuais de tela cheia (fullscreen) e controle de som para cada viewport na grade.

---

## 🧪 Como Testar / How to Test
1. Inicie o servidor MediaMTX pelo launcher `DJI-Stream-Hub.exe`.
2. Configure duas instâncias de transmissão diferentes:
   * **Fluxo 1 (Celular 1):** Transmita para `rtmp://IP_DO_PC:1935/live/drone1`
   * **Fluxo 2 (Celular 2/OBS de simulação):** Transmita para `rtmp://IP_DO_PC:1935/live/drone2`
3. No painel web do computador, selecione o layout **"Grade 2x2"** ou **"Lado a Lado"**.
4. Verifique se o painel abre dois players de vídeo independentes na tela.
5. Confirme que ambos os feeds de vídeo estão sendo exibidos simultaneamente com latência ultra-baixa de forma independente.
6. Teste o botão de **Tela Cheia** de cada um dos feeds individuais e verifique se eles expandem e retornam à grade corretamente.

---

## 📋 Testes de Aceitação / Acceptance Criteria
- [ ] Suporte a exibição de até 4 transmissões simultâneas locais e offline com custo zero de processamento na nuvem.
- [ ] A interface da grade é responsiva, adaptando o tamanho dos players de forma harmoniosa tanto em monitores ultrawide quanto em telas Full HD comuns.
- [ ] O áudio de cada player inicia silenciado por padrão (mute) para evitar poluição sonora, permitindo ativar individualmente.
