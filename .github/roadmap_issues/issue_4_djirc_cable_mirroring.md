# Issue #4: [Feature] DJI RC Wired Screen Mirroring (Boot Handshake Integration) 🔌

## 📝 Descrição / Description
Os controles DJI RC comuns (com tela cinza de antenas internas) possuem o sistema operacional Android altamente bloqueado pelas atualizações recentes da DJI, impedindo a ativação nativa do ADB e transmissão por RTMP. Esta Issue propõe integrar a solução de hardware descoberta pela comunidade: espelhar a tela do DJI RC comum via cabo HDMI físico através de uma placa de captura de vídeo barata usando o comportamento oculto de "Boot Handshake".

---

## 🛠️ Solução Proposta / Proposed Solution
- Adicionar uma nova aba chamada **"Modo Cabo (DJI RC/RC2)"** no painel da dashboard (`dashboard.html`).
- Esta aba conterá um passo a passo visual e ilustrado ensinando o usuário a realizar o "Handshake de Inicialização" (plugar o cabo com o controle desligado e ligá-lo depois).
- Usar a API nativa do navegador de acesso a mídias (`navigator.mediaDevices.getUserMedia`) para ler a placa de captura USB (que se comporta como uma webcam padrão para o Windows).
- Renderizar o feed da placa de captura diretamente no player da dashboard, permitindo que a tela inteira do controle seja espelhada no PC com latência zero absoluta e gravada localmente.

---

## 🧪 Como Testar / How to Test
1. Conecte uma Placa de Captura de Vídeo USB/HDMI barata na porta USB do seu computador Windows.
2. Com o controle **DJI RC desligado**, conecte o cabo USB-C para HDMI ligando o controle à placa de captura.
3. Ligue o controle DJI RC e aguarde o processo de boot completo do controle terminar.
4. No computador, abra o `dashboard.html` e selecione a aba **"Modo Cabo (DJI RC/RC2)"**.
5. Quando solicitado pelo navegador, dê permissão para acessar a câmera do sistema.
6. Selecione a placa de captura (ex: "USB Video") na lista de dispositivos.
7. Verifique se o feed do controle DJI RC aparece instantaneamente e de forma fluida no painel em tempo real, sem atrasos.

---

## 📋 Testes de Aceitação / Acceptance Criteria
- [ ] O recurso funciona em qualquer firmware do controle DJI RC comum, sem exigir hacks de software, adulterações ou risco de queimar o dispositivo (bricking).
- [ ] O espelhamento funciona com latência zero e custo de processamento/licenciamento zero.
- [ ] A interface fornece instruções claras em Inglês e Português para que qualquer usuário comum consiga executar o "Boot Handshake" sem dificuldades.
