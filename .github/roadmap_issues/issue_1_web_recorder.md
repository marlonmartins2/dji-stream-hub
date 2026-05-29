# Issue #1: [Feature] Local Direct Flight Recording in Dashboard (Web-Recorder) ⏺️

## 📝 Descrição / Description
Atualmente, se o piloto deseja gravar o feed de vídeo da transmissão do drone que chega no PC, ele precisa instalar e configurar uma ferramenta externa complexa como o OBS Studio. Esta Issue propõe a criação de um recurso de gravação nativo direto na interface web do painel (`dashboard.html`), permitindo salvar o vídeo do voo com um clique.

---

## 🛠️ Solução Proposta / Proposed Solution
- Adicionar um botão flutuante estilizado de "Gravar Voo" (com indicador de gravação vermelho piscante) no painel de reprodução de vídeo WebRTC do `dashboard.html`.
- Usar a API nativa do navegador `MediaRecorder API` para capturar a trilha de mídia (vídeo/áudio) em execução no elemento `<video>` do WebRTC.
- Processar a gravação inteiramente no navegador do cliente (100% offline).
- Ao clicar em "Parar Gravação", gerar um arquivo `.mp4` ou `.webm` de alta qualidade e forçar o download direto para a pasta "Downloads" do usuário no Windows.

---

## 🧪 Como Testar / How to Test
1. Inicie o servidor executando o `DJI-Stream-Hub.exe`.
2. Conecte o aplicativo DJI Fly no celular à transmissão RTMP para gerar o feed no PC.
3. No painel web aberto no PC, clique no novo botão **"Gravar Voo"**.
4. Observe o cronômetro de gravação iniciar e o ícone vermelho piscar no topo do player.
5. Deixe gravando por 10 a 15 segundos, realizando movimentos na câmera do drone para validar os quadros de vídeo.
6. Clique no botão **"Parar Gravação"**.
7. Verifique se o navegador exibe a janela de salvamento ou faz o download automático de um arquivo de vídeo com nome formatado (ex: `dji_flight_YYYY-MM-DD_HH-MM-SS.mp4`).
8. Abra o vídeo gravado no player de mídia do Windows e verifique a integridade da imagem, fluidez e sincronia.

---

## 📋 Testes de Aceitação / Acceptance Criteria
- [ ] A gravação funciona de forma 100% local, com custo de servidor e processamento em nuvem rigorosamente zero.
- [ ] O processo de gravação não introduz lag ou travamento (drop frames) na transmissão WebRTC ao vivo.
- [ ] O arquivo final é baixado em formato padrão reproduzível no Windows Media Player ou VLC.
- [ ] O botão de gravação muda de estado visualmente (de "Gravar" para "Gravando [00:05]" piscando) para feedback claro do usuário.
