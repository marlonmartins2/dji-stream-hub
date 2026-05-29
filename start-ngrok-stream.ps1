# ==============================================================================
# DJI Low-Latency Stream Hub - Inicialização Automatizada via Ngrok
# OS: Windows (PowerShell 5.1+)
# ==============================================================================

# Configurações de codificação para caracteres especiais em Português
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Clear-Host
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "       DJI MINI 3 - NGROK STREAMING AUTOMATION SYSTEM" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Iniciando processo de automação com túnel seguro..." -ForegroundColor Gray

# Recarrega a variável PATH para garantir que o ngrok instalado seja encontrado
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","User") + ";" + [System.Environment]::GetEnvironmentVariable("Path","Machine")

# 1. Limpa processos antigos para liberar as portas
Write-Host "`n[1/5] Liberando portas locais..." -ForegroundColor Gray
Stop-Process -Name mediamtx -Force -ErrorAction SilentlyContinue
Stop-Process -Name ngrok -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# 2. Inicia o MediaMTX local
Write-Host "[2/5] Iniciando servidor de mídia local (MediaMTX)..." -ForegroundColor Gray
if (-not (Test-Path "mediamtx.exe")) {
    Write-Host "[ERRO] mediamtx.exe não encontrado! Por favor, execute o start-stream.ps1 primeiro para baixá-lo." -ForegroundColor Red
    Read-Host "Pressione Enter para sair..."
    exit
}

try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = ".\mediamtx.exe"
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $mediaMtxProcess = [System.Diagnostics.Process]::Start($psi)
    Write-Host "-> MediaMTX rodando silenciosamente (ID: $($mediaMtxProcess.Id))" -ForegroundColor Green
} catch {
    Write-Host "[ERRO] Falha ao iniciar o MediaMTX: $_" -ForegroundColor Red
    exit
}

# 3. Inicia o Túnel Ngrok
Write-Host "[3/5] Abrindo túnel TCP seguro com Ngrok para a porta 1935..." -ForegroundColor Gray
try {
    $psiNgrok = New-Object System.Diagnostics.ProcessStartInfo
    $psiNgrok.FileName = "ngrok"
    $psiNgrok.Arguments = "tcp 1935"
    $psiNgrok.CreateNoWindow = $true
    $psiNgrok.UseShellExecute = $false
    $ngrokProcess = [System.Diagnostics.Process]::Start($psiNgrok)
    Write-Host "-> Túnel Ngrok iniciado silenciosamente em segundo plano (ID: $($ngrokProcess.Id))" -ForegroundColor Green
} catch {
    Write-Host "[ERRO CRÍTICO] Falha ao iniciar o ngrok! Verifique se a autenticação foi concluída." -ForegroundColor Red
    Stop-Process -Id $mediaMtxProcess.Id -Force -ErrorAction SilentlyContinue
    exit
}

# 4. Aguarda a inicialização do Ngrok e obtém a URL pública
Write-Host "[4/5] Aguardando conexão do túnel ngrok..." -ForegroundColor Gray
$ngrokUrl = $null
$attempts = 0
$maxAttempts = 10

while ($null -eq $ngrokUrl -and $attempts -lt $maxAttempts) {
    Start-Sleep -Seconds 1
    $attempts++
    try {
        # Consulta a API local do ngrok para pegar os túneis ativos
        $tunnelsInfo = Invoke-RestMethod -Uri "http://127.0.0.1:4040/api/tunnels" -UseBasicParsing
        if ($tunnelsInfo -and $tunnelsInfo.tunnels -and $tunnelsInfo.tunnels.Count -gt 0) {
            $ngrokUrl = $tunnelsInfo.tunnels[0].public_url
        }
    } catch {
        # A API do ngrok ainda pode estar subindo, continua tentando
    }
}

if ($null -eq $ngrokUrl) {
    Write-Host "[ERRO CRÍTICO] O ngrok não conseguiu estabelecer a conexão pública!" -ForegroundColor Red
    Write-Host "Verifique sua conexão com a internet ou se o seu Authtoken está correto." -ForegroundColor Red
    Stop-Process -Id $mediaMtxProcess.Id -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $ngrokProcess.Id -Force -ErrorAction SilentlyContinue
    Read-Host "Pressione Enter para sair..."
    exit
}

# Converte o link tcp:// do ngrok para rtmp://
$rtmpNgrokUrl = $ngrokUrl -replace "tcp://", "rtmp://"
$rtmpFullUrl = "$rtmpNgrokUrl/live/drone"

Write-Host "-> Túnel conectado com sucesso!" -ForegroundColor Green
Write-Host "-> URL de Transmissão Pública: $rtmpFullUrl" -ForegroundColor Cyan

# 5. Atualiza o painel local (config.js) com as informações do túnel
Write-Host "`n[5/5] Atualizando o painel web interativo..." -ForegroundColor Gray
$timestamp = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
$configJsContent = @"
// Configuração gerada dinamicamente pelo script de inicialização do Ngrok
const STREAM_CONFIG = {
  pcName: "$env:COMPUTERNAME",
  localIp: "localhost",
  ngrokUrl: "$rtmpFullUrl",
  streamPath: "live/drone",
  rtmpPort: 1935,
  rtspPort: 8554,
  webrtcPort: 8889,
  generatedAt: "$timestamp"
};
"@

$configJsContent | Out-File -FilePath "config.js" -Encoding utf8 -Force
Write-Host "-> config.js atualizado." -ForegroundColor Green

# Abre o dashboard local no navegador
try {
    Start-Process "dashboard.html"
    Write-Host "-> Painel aberto no navegador!" -ForegroundColor Green
} catch {
    Write-Host "-> Abra o arquivo 'dashboard.html' manualmente." -ForegroundColor Yellow
}

# Mantém ativo e aguarda encerramento
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "              SISTEMA PRONTO E TÚNEL SEGURO ATIVO!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  -> Digite este endereço no app DJI Fly:" -ForegroundColor Yellow
Write-Host "     $rtmpFullUrl" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------" -ForegroundColor Gray
Write-Host "  Mantenha esta janela aberta enquanto estiver voando." -ForegroundColor White
Write-Host "  Para encerrar o servidor e fechar o túnel com segurança," -ForegroundColor White
Write-Host "  pressione qualquer tecla nesta janela." -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Cyan

# Aguarda qualquer entrada do usuário
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Encerramento gracioso
Write-Host "`nDesligando serviços..." -ForegroundColor Yellow
Stop-Process -Id $mediaMtxProcess.Id -Force -ErrorAction SilentlyContinue
Stop-Process -Id $ngrokProcess.Id -Force -ErrorAction SilentlyContinue
Write-Host "-> Servidor e túnel encerrados com sucesso. Obrigado!" -ForegroundColor Green
Start-Sleep -Seconds 1
