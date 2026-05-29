# DJI Low-Latency Live Streaming Hub 🚀

Este projeto é uma solução automatizada projetada para transmitir a imagem em tempo real do seu drone **DJI Mini 3** (usando o controle **DJI RC-N1** e seu smartphone rodando o aplicativo **DJI Fly**) para o seu computador Windows, com **latência de ultra-baixa (atraso inferior a 300ms)**.

A latência mínima é alcançada transmitindo na sua rede Wi-Fi local e convertendo instantaneamente o protocolo de ingestão **RTMP** para o protocolo de entrega em tempo real **WebRTC** (baseado em UDP), eliminando completamente os buffers e atrasos do processamento na nuvem.

---

## 📁 Estrutura do Projeto

* **`DJI-Stream-Hub.exe`**: Executável principal (Launcher). Inicia o sistema com privilégios de Administrador de forma automatizada e contorna políticas de segurança do Windows.
* `compile-launcher.ps1`: Script automatizado para compilar/gerar o executável `DJI-Stream-Hub.exe` a partir de seu código-fonte C# nativo embutido.
* `start-stream.ps1`: Script em PowerShell contendo a lógica de rede, automação do Hotspot e inicialização do MediaMTX.
* `dashboard.html`: Painel web interativo com interface premium em Dark Mode / Glassmorphism, reprodutor WebRTC e guias integrados.
* `mediamtx_template.yml`: Configuração otimizada para performance máxima e latência mínima.
* `config.js`: Gerado dinamicamente pelo script com o endereço de IP e portas locais do computador.

---

## 🛠️ Pré-requisitos no Windows

1. **PowerShell 5.1 ou superior:** Já vem instalado nativamente no Windows 10/11.
2. **Permissão de Script no PowerShell:** Por padrão, o Windows bloqueia a execução de scripts baixados da internet. Para liberar de forma segura no seu usuário local, siga o passo abaixo:
   * Abra o PowerShell como Administrador e execute o comando:
     ```powershell
     Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
     ```

---

## ⚡ Como Usar (Passo a Passo)

### Passo 1: Executar o Servidor no PC
1. Dê um duplo clique no arquivo **`DJI-Stream-Hub.exe`**.
2. O launcher irá:
   * Solicitar automaticamente permissão de Administrador (elevação UAC) para que o Hotspot Móvel e Firewall do Windows possam ser configurados sem erros.
   * Executar o PowerShell ignorando de forma transparente qualquer política de execução restrita do Windows.
   * Iniciar o servidor de mídia seguro **MediaMTX** e abrir o **Painel Web Premium** no seu navegador de internet padrão.
3. Deixe a janela do terminal aberta. Ela exibirá o IP e a porta que você deve digitar no celular.

### Passo 2: Conectar o Celular à mesma Rede
1. No seu computador, habilite a função **Hotspot Móvel** do Windows (Ancoragem Wi-Fi).
2. No seu smartphone (conectado ao controle do drone), conecte-se à rede Wi-Fi criada pelo Hotspot do computador.
   * *Nota: Isso garante que os dados trafeguem diretamente entre o celular e o computador com o menor atraso possível.*

### Passo 3: Iniciar a Transmissão no DJI Fly
1. Ligue o drone DJI Mini 3 e o controle. Abra o app **DJI Fly** e acesse a tela de câmera do drone.
2. Toque nos **3 pontinhos (...)** no canto superior direito da tela de voo.
3. Vá na aba **Transmissão (Transmission)**.
4. Toque em **Plataformas de Transmissão ao Vivo (Live Streaming Platforms)** e selecione **RTMP**.
5. No campo do link de transmissão, cole ou digite o endereço exibido no topo do seu Painel Web (exemplo: `rtmp://192.168.137.1:1935/live/drone`).
6. Escolha a resolução desejada e a taxa de bits (recomendamos **720p a 3 Mbps** para o melhor equilíbrio entre qualidade e latência estável).
7. Clique em **Iniciar Transmissão**.

### Passo 4: Visualizar com Latência Zero!
1. Assim que a transmissão for iniciada no celular, o Painel Web no seu computador carregará o feed do drone automaticamente em tempo real!
2. Você pode clicar no botão de **Tela Cheia (Fullscreen)** para monitorar em tela cheia no PC.

---

## 🎬 Integração com o OBS Studio

Para gravar ou fazer lives profissionais usando o feed do drone no OBS:

### Método A: Captura por Navegador WebRTC (Menor Delay)
1. Ao invés do OBS, você pode usar a captura de janela do painel, ou no OBS Studio, clicar no **`+`** sob Fontes e selecionar **Navegador (Browser)**.
2. No campo de URL, cole o link WebRTC exibido na aba "Integração OBS" do painel (ex: `http://127.0.0.1:8889/live/drone`).
3. Ajuste a resolução na fonte para `1920` x `1080` e confirme.

### Método B: Fonte de Mídia RTSP/UDP (Super Estável)
1. No OBS, clique no **`+`** sob Fontes e selecionar **Fonte de Mídia (Media Source)**.
2. Desmarque a caixa "Arquivo Local".
3. No campo **Entrada (Input)**, cole o link RTSP (ex: `rtsp://127.0.0.1:8554/live/drone`).
4. No campo **Opções de Entrada (Input Options)**, digite: `rtsp_transport=udp`.
5. Confirme. O vídeo carregará com delay de aproximadamente 300ms a 400ms.

---

## ❌ Encerramento Seguro

Quando terminar de voar:
1. Pare a transmissão no aplicativo DJI Fly.
2. Vá até a janela preta do PowerShell no seu PC e **pressione qualquer tecla**.
3. O script irá desligar o servidor MediaMTX com segurança e fechar a janela, liberando as portas de rede do seu computador.

---

## 🔍 Solução de Problemas

* **Erro de Firewall:** Na primeira execução, o Windows pode perguntar se deseja dar permissão de rede ao MediaMTX. Certifique-se de marcar as redes **Públicas e Privadas** e clique em **Permitir Acesso**.
* **IP Incorreto:** Se você possui várias placas de rede virtuais (como Docker, VirtualBox, WSL ou VPN), o script pode selecionar o IP incorreto. Você pode ver todos os IPs válidos na aba **Diagnóstico** do painel e substituir manualmente o IP no link da stream.
* **Vídeo Engasgando:** Se a conexão Wi-Fi oscilar, o vídeo pode apresentar travamentos. Tente aproximar o celular do computador ou reduza a qualidade de transmissão no app DJI Fly para 720p com taxa de bits em 3 Mbps.

---

## 🛠️ Como Recompilar ou Gerar o Executável (.exe)

Se você desejar reconstruir, modificar ou gerar novamente o executável principal `DJI-Stream-Hub.exe`:
1. Clique com o botão direito no arquivo **`compile-launcher.ps1`** e selecione **"Executar com o PowerShell"**.
2. O script localizará automaticamente o compilador C# nativo do Windows (`csc.exe`), criará os arquivos temporários necessários, compilará o código-fonte C# integrado e limpará o espaço de trabalho após gerar um novo executável `DJI-Stream-Hub.exe` limpo e funcional!
