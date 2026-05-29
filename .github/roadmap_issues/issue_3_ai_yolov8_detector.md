# Issue #3: [Feature] Local AI Object Detection (YOLOv8 + OpenCV) 🧠

## 📝 Descrição / Description
Deseja-se transformar o DJI Stream Hub em uma ferramenta avançada e autônoma de vigilância e busca/salvamento (Search & Rescue). Para isso, propõe-se adicionar suporte à análise de imagem em tempo real com inteligência artificial para detectar pessoas, veículos, barcos e obstáculos direto na stream local, sem custos com APIs de nuvem.

---

## 🛠️ Solução Proposta / Proposed Solution
- Criar um script Python opcional e autocontido no diretório do projeto (`ai_detector.py`).
- O script usará a biblioteca `OpenCV` e o modelo pré-treinado super leve `YOLOv8 nano` (local, gratuito e executável via CPU ou GPU local).
- O script se conectará ao feed local do MediaMTX via protocolo RTSP (`rtsp://localhost:8554/live/drone`).
- O YOLOv8 processará os frames em tempo real, desenhará retângulos e porcentagens de precisão nos objetos detectados e gerará um novo fluxo de vídeo de saída direcionado de volta ao MediaMTX (ex: `rtmp://localhost:1935/live/drone-ai`).
- Adicionar uma aba "Visualização com IA" na dashboard para renderizar este fluxo processado.

---

## 🧪 Como Testar / How to Test
1. Certifique-se de ter o Python 3.9+ instalado no seu computador.
2. Inicie a stream do drone (ou uma stream de teste via OBS) apontada para o `DJI-Stream-Hub.exe`.
3. Abra um terminal na pasta do projeto e instale as dependências locais:
   `pip install ultralytics opencv-python-headless`
4. Execute o script detector:
   `python .\ai_detector.py`
5. Na aba "Visualização com IA" no `dashboard.html`, ligue o player secundário.
6. Aponte a câmera do drone para objetos comuns (pessoas, computadores, carros ou garrafas de água).
7. Verifique se o feed na dashboard exibe com precisão caixas de marcação verdes em cima dos objetos detectados com latência aceitável (menor que 500ms).

---

## 📋 Testes de Aceitação / Acceptance Criteria
- [ ] A análise de imagem ocorre de forma 100% offline, rodando localmente na GPU/CPU do computador, mantendo o custo operacional em zero absoluto.
- [ ] O script Python não interfere no feed de vídeo original (`live/drone`), garantindo que o piloto tenha sempre a imagem limpa de segurança de voo disponível.
- [ ] A taxa de quadros (FPS) da detecção com IA é de no mínimo 15 FPS em computadores comuns sem GPU dedicada.
- [ ] As bounding boxes possuem rótulos claros em contraste (ex: "Pessoa: 89%" em verde neon).
