# ==============================================================================
# DJI Low-Latency Stream Hub - Script de Inicialização Automatizada
# OS: Windows (PowerShell 5.1+)
# ==============================================================================

# Configurações de codificação para caracteres especiais em Português
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host
Write-Host " ┌────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host " │              DJI STREAM HUB - LATÊNCIA ULTRA-BAIXA         │" -ForegroundColor White
Write-Host " │  Sistema Local de Transmissão de Alta Performance para DJI │" -ForegroundColor Gray
Write-Host " └────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host "   [⚙] Inicializando ecossistema de streaming..." -ForegroundColor Gray

# ------------------------------------------------------------------------------
# 0. CONFIGURAÇÃO AUTOMÁTICA DO HOTSPOT MÓVEL (Se rodar como Administrador)
# ------------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "`n  📶 [Hotspot] Configurando rede Wi-Fi local..." -ForegroundColor Cyan
    try {
        [void][Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType=WindowsRuntime]
        [void][Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager, Windows.Networking.NetworkOperators, ContentType=WindowsRuntime]
        
        $profile = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile()
        if ($null -ne $profile) {
            $manager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager]::CreateFromConnectionProfile($profile)
            
            # Configura SSID e Senha Padrão
            $config = $manager.GetCurrentAccessPointConfiguration()
            $config.Ssid = "DJI-Stream-Hub"
            $config.Passphrase = "djidrone123"
            
            $asyncOp = $manager.ConfigureAccessPointAsync($config)
            while ($asyncOp.Status -eq "Started" -or $asyncOp.Status -eq 0) { Start-Sleep -Milliseconds 100 }
            Write-Host "     ✔ Rede Wi-Fi definida: SSID 'DJI-Stream-Hub' | Senha 'djidrone123'" -ForegroundColor Green
            
            # Liga o Hotspot se estiver desligado
            if ($manager.TetheringOperationalState -ne 1) {
                Write-Host "     ⚙ Ativando transmissor Wi-Fi do Hotspot..." -ForegroundColor Gray
                $null = $manager.StartTetheringAsync()
                $attempts = 0
                while ($manager.TetheringOperationalState -ne 1 -and $attempts -lt 50) {
                    Start-Sleep -Milliseconds 100
                    $attempts++
                }
            }
            
            if ($manager.TetheringOperationalState -eq 1) {
                Write-Host "     ✔ Hotspot Móvel ATIVADO e pronto para conexões!" -ForegroundColor Green
            } else {
                Write-Host "     ⚠ O Hotspot está em inicialização. Pode levar alguns segundos..." -ForegroundColor Yellow
            }
        } else {
            Write-Host "     ⚠ Nenhuma conexão de Internet ativa encontrada para compartilhar no Hotspot." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "     ⚠ Falha ao ativar Hotspot via código: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n  💡 [Dica] Execute o aplicativo como Administrador para configurar e" -ForegroundColor Gray
    Write-Host "     ligar o Hotspot ('DJI-Stream-Hub' / 'djidrone123') automaticamente!" -ForegroundColor Gray
}

# ------------------------------------------------------------------------------
# 1. DETECÇÃO INTELIGENTE DE IP LOCAL
# ------------------------------------------------------------------------------
Write-Host "`n  [1/5] 🔍 Detectando adaptadores de rede ativos..." -ForegroundColor Gray

# Obtém interfaces ativas com IPv4 (filtrando adaptadores virtuais para evitar IPs falsos)
$interfaces = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.IPAddress -notlike "127.*" -and 
    $_.IPAddress -notlike "169.254.*" -and 
    $_.InterfaceAlias -notlike "*Loopback*" -and
    $_.InterfaceAlias -notlike "*vEthernet*" -and
    $_.InterfaceAlias -notlike "*WSL*" -and
    $_.InterfaceAlias -notlike "*Virtual*" -and
    $_.InterfaceAlias -notlike "*VPN*" -and
    $_.InterfaceAlias -notlike "*Bluetooth*" -and
    $_.InterfaceAlias -notlike "*Surfshark*"
}

if ($interfaces.Count -eq 0) {
    Write-Host "`n  [ERRO] Nenhum adaptador de rede ativo encontrado!" -ForegroundColor Red
    Write-Host "  Verifique se o Wi-Fi ou o Hotspot estão ligados." -ForegroundColor Red
    Read-Host "  Pressione Enter para sair..."
    exit
}

# Escolha inteligente da rede: 
# Prioriza 1: Hotspot Móvel do Windows (Microsoft Wi-Fi Direct - geralmente começa com 192.168.137.x)
# Prioriza 2: Wi-Fi Convencional
# Prioriza 3: Ethernet
$selectedIp = $null
$selectedInterfaceName = ""

# Procura hotspot (geralmente rede 192.168.137.x ou Wi-Fi Direct)
foreach ($if in $interfaces) {
    if ($if.IPAddress -like "192.168.137.*" -or $if.InterfaceAlias -like "*Wi-Fi Direct*" -or $if.InterfaceAlias -like "*Hotspot*") {
        $selectedIp = $if.IPAddress
        $selectedInterfaceName = $if.InterfaceAlias + " (Hotspot Móvel)"
        break
    }
}

# Se não encontrou Hotspot, pega a primeira interface Wi-Fi ativa
if ($null -eq $selectedIp) {
    foreach ($if in $interfaces) {
        if ($if.InterfaceAlias -like "*Wi-Fi*" -or $if.InterfaceAlias -like "*Wireless*") {
            $selectedIp = $if.IPAddress
            $selectedInterfaceName = $if.InterfaceAlias + " (Wi-Fi Local)"
            break
        }
    }
}

# Se ainda não encontrou, pega o primeiro IP ativo disponível
if ($null -eq $selectedIp) {
    $selectedIp = $interfaces[0].IPAddress
    $selectedInterfaceName = $interfaces[0].InterfaceAlias
}

Write-Host "     ✔ Interface ativa: $selectedInterfaceName" -ForegroundColor Green
Write-Host "     ✔ Endereço IP local: $selectedIp" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 2. DOWNLOAD E INSTALAÇÃO DO MEDIAMTX (Se necessário)
# ------------------------------------------------------------------------------
Write-Host "`n  [2/5] 📦 Verificando servidor de mídia (MediaMTX)..." -ForegroundColor Gray
$executableName = "mediamtx.exe"
$zipName = "mediamtx_windows_amd64.zip"

if (Test-Path $executableName) {
    Write-Host "     ✔ Servidor MediaMTX localizado e pronto para execução." -ForegroundColor Green
} else {
    Write-Host "     ⚙ MediaMTX não encontrado. Iniciando instalação automática..." -ForegroundColor Cyan
    
    # Versão estável padrão caso a API falhe
    $defaultVersion = "v1.9.0"
    $zipUrl = "https://github.com/bluenviron/mediamtx/releases/download/v1.9.0/mediamtx_v1.9.0_windows_amd64.zip"
    
    try {
        Write-Host "     Buscando última versão no repositório oficial..." -ForegroundColor Gray
        # Configura protocolo TLS seguro
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/bluenviron/mediamtx/releases/latest" -UseBasicParsing
        if ($releaseInfo -and $releaseInfo.tag_name) {
            $latestVersion = $releaseInfo.tag_name
            $zipUrl = "https://github.com/bluenviron/mediamtx/releases/download/$latestVersion/mediamtx_${latestVersion}_windows_amd64.zip"
            Write-Host "     -> Última versão estável: $latestVersion" -ForegroundColor Gray
        }
    } catch {
        Write-Host "     -> Falha ao consultar API do GitHub. Usando versão estável: $defaultVersion" -ForegroundColor Yellow
    }

    Write-Host "     Baixando pacote do MediaMTX..." -ForegroundColor Gray
    try {
        # Faz o download de forma otimizada
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($zipUrl, $zipName)
        Write-Host "     ✔ Download concluído com sucesso!" -ForegroundColor Green
        
        Write-Host "     Extraindo arquivos do zip..." -ForegroundColor Gray
        # Extrai silenciosamente
        Expand-Archive -Path $zipName -DestinationPath "." -Force
        
        # Limpa o arquivo zip baixado
        Remove-Item $zipName -Force
        Write-Host "     ✔ Instalação concluída com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "`n  [ERRO CRÍTICO] Falha ao baixar ou extrair o MediaMTX!" -ForegroundColor Red
        Write-Host "  Detalhes: $_" -ForegroundColor Red
        Write-Host "  Por favor, verifique sua conexão com a internet e tente novamente." -ForegroundColor Red
        Read-Host "  Pressione Enter para sair..."
        exit
    }
}

# ------------------------------------------------------------------------------
# 3. CONFIGURAÇÃO DINÂMICA DO SERVIDOR
# ------------------------------------------------------------------------------
Write-Host "`n  [3/5] ⚙ Otimizando parâmetros de streaming..." -ForegroundColor Gray

$templatePath = "mediamtx_template.yml"
$configPath = "mediamtx.yml"

if (Test-Path $templatePath) {
    # Copia o template otimizado para o arquivo de execução padrão do MediaMTX
    Copy-Item $templatePath $configPath -Force
    Write-Host "     ✔ Configurações de latência ultrabaixa aplicadas com sucesso." -ForegroundColor Green
} else {
    Write-Host "     ⚠ Template 'mediamtx_template.yml' não encontrado. Usando padrões nativos." -ForegroundColor Yellow
}

# Grava dinamicamente o config.js com as variáveis do IP local
$timestamp = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
$configJsContent = @"
// Configuração gerada dinamicamente pelo script de inicialização do Windows
const STREAM_CONFIG = {
  pcName: "$env:COMPUTERNAME",
  localIp: "$selectedIp",
  streamPath: "live/drone",
  rtmpPort: 1935,
  rtspPort: 8554,
  webrtcPort: 8889,
  generatedAt: "$timestamp"
};
"@

$configJsContent | Out-File -FilePath "config.js" -Encoding utf8 -Force
Write-Host "     ✔ Configurações dinâmicas do Painel Web geradas para o IP: $selectedIp" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. INICIALIZAÇÃO E ABERTURA DO PAINEL
# ------------------------------------------------------------------------------
Write-Host "`n  [4/5] 🚀 Inicializando servidor MediaMTX em segundo plano..." -ForegroundColor Gray

# Verifica se a porta RTMP (1935) já está sendo utilizada
$portCheck = Get-NetTCPConnection -LocalPort 1935 -ErrorAction SilentlyContinue
if ($portCheck) {
    Write-Host "`n  [⚙] Porta 1935 (RTMP) em uso. Tentando liberar automaticamente..." -ForegroundColor Yellow
    
    # Obtém os PIDs exclusivos que estão utilizando a porta
    $pids = $portCheck.OwningProcess | Select-Object -Unique
    
    foreach ($targetPid in $pids) {
        if ($targetPid -gt 0) {
            try {
                $proc = Get-Process -Id $targetPid -ErrorAction SilentlyContinue
                if ($proc) {
                    $procName = $proc.Name
                    Write-Host "     ⚙ Encerrando processo '$procName' (PID: $targetPid) para liberar a porta..." -ForegroundColor Gray
                    Stop-Process -Id $targetPid -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Host "     ⚠ Falha ao encerrar o processo PID $($targetPid): $_" -ForegroundColor Yellow
            }
        }
    }
    
    # Aguarda a liberação dos sockets pelo sistema operacional
    Start-Sleep -Seconds 2
    
    # Re-verifica a porta 1935
    $portCheckAfter = Get-NetTCPConnection -LocalPort 1935 -ErrorAction SilentlyContinue
    if ($portCheckAfter) {
        Write-Host "`n  [ERRO CRÍTICO] A porta 1935 (RTMP) continua ocupada e não pôde ser liberada!" -ForegroundColor Red
        Write-Host "  Por favor, encerre manualmente o aplicativo na porta 1935 e reinicie o Hub." -ForegroundColor Red
        Read-Host "  Pressione Enter para sair..."
        exit
    } else {
        Write-Host "     ✔ Porta 1935 liberada com sucesso e pronta para uso!" -ForegroundColor Green
    }
}

# Inicia o executável com janela totalmente oculta para ter apenas um terminal visível
try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = ".\mediamtx.exe"
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $serverProcess = [System.Diagnostics.Process]::Start($psi)
    Write-Host "     ✔ Servidor ativo (Processo ID: $($serverProcess.Id) | Porta RTMP: 1935 | WebRTC: 8889)" -ForegroundColor Green
} catch {
    Write-Host "`n  [ERRO CRÍTICO] Falha ao executar mediamtx.exe!" -ForegroundColor Red
    Write-Host "  Detalhes: $_" -ForegroundColor Red
    Read-Host "  Pressione Enter para sair..."
    exit
}

# Aguarda o servidor subir
Start-Sleep -Seconds 1

Write-Host "`n  [5/5] 🖥️ Abrindo Painel de Controle DJI Stream Hub..." -ForegroundColor Gray
try {
    Start-Process "dashboard.html"
    Write-Host "     ✔ Painel carregado com sucesso no navegador padrão!" -ForegroundColor Green
} catch {
    Write-Host "     ⚠ Não foi possível abrir automaticamente. Abra o arquivo 'dashboard.html' manualmente." -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------
# 5. GERENCIAMENTO DE CICLO DE VIDA (Graceful Shutdown)
# ------------------------------------------------------------------------------
Write-Host "`n ┌────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host " │                 CONEXÃO PRONTA E ATIVA!                    │" -ForegroundColor Green
Write-Host " ├────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
Write-Host " │                                                            │" -ForegroundColor White
Write-Host " │  1. No aplicativo DJI Fly no seu dispositivo móvel,        │" -ForegroundColor White
Write-Host " │     vá em: Configurações -> Transmissão -> Transmitir      │" -ForegroundColor White
Write-Host " │                                                            │" -ForegroundColor White
Write-Host " │  2. Cole a URL de RTMP abaixo exatamente como descrita:     │" -ForegroundColor White
Write-Host " │                                                            │" -ForegroundColor White
Write-Host " │     " -NoNewline -ForegroundColor White
Write-Host "rtmp://${selectedIp}:1935/live/drone" -ForegroundColor Yellow -NoNewline
# Pad with spaces to fit the box border
$paddingLength = 55 - ("rtmp://${selectedIp}:1935/live/drone").Length
if ($paddingLength -gt 0) {
    Write-Host (" " * $paddingLength) -NoNewline
}
Write-Host "│" -ForegroundColor Cyan
Write-Host " │                                                            │" -ForegroundColor White
Write-Host " ├────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
Write-Host " │  [i] Mantenha esta janela aberta enquanto voa.             │" -ForegroundColor Gray
Write-Host " │  [x] Pressione QUALQUER TECLA para fechar com segurança.    │" -ForegroundColor Gray
Write-Host " └────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan

# Aguarda qualquer entrada do usuário no console
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Encerramento gracioso do servidor
Write-Host "`n  🛑 Desligando servidores e liberando portas..." -ForegroundColor Yellow
try {
    if (-not $serverProcess.HasExited) {
        Stop-Process -Id $serverProcess.Id -Force
        Write-Host "     ✔ Servidor MediaMTX encerrado com sucesso." -ForegroundColor Green
    }
} catch {
    Write-Host "     ✔ Servidor já estava inativo." -ForegroundColor Gray
}

Write-Host "`n  ✨ Obrigado por voar com o DJI Stream Hub! Até a próxima." -ForegroundColor Green
Start-Sleep -Seconds 2
