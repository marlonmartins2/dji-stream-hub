# ==============================================================================
# DJI Low-Latency Stream Hub - Compilador do Executável do Launcher com Ícone
# OS: Windows (PowerShell 5.1+)
# ==============================================================================

# Configurações de codificação para caracteres especiais em Português
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Clear-Host
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "         COMPILADOR AUTOMÁTICO DO LAUNCHER (.EXE)" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Cyan

# 1. BUSCAR LOGOTIPO E GERAR APP.ICO
Write-Host "Buscando logotipo do projeto..." -ForegroundColor Gray

$logoPath = "logo.png"
$logoFound = $false

# 1. Verifica se logo.png já existe no diretório local
if (Test-Path $logoPath) {
    Write-Host "-> Logotipo encontrado localmente: logo.png" -ForegroundColor Green
    $logoFound = $true
} else {
    # 2. Fallback para a pasta do cérebro da sessão (apenas se existir no computador do desenvolvedor original)
    $brainDir = "C:\Users\marlo\.gemini\antigravity\brain\7e06a34e-fc03-4fef-bf3e-d678beaee7d3"
    if (Test-Path $brainDir) {
        $logoFile = Get-ChildItem -Path $brainDir -Filter "media__*.png" | 
                    Where-Object { $_.Length -gt 1000 } | 
                    Sort-Object LastWriteTime -Descending | 
                    Select-Object -First 1
        
        if ($null -ne $logoFile) {
            Write-Host "-> Logotipo encontrado no cérebro: $($logoFile.Name)" -ForegroundColor Green
            Copy-Item $logoFile.FullName $logoPath -Force
            Write-Host "-> 'logo.png' copiado para o diretório local." -ForegroundColor Green
            $logoFound = $true
        }
    }
}

if ($logoFound) {
    # Converte o logo para app.ico usando System.Drawing e empacotamento PNG ICO nativo de alta qualidade (256x256)
    try {
            Write-Host "Convertendo 'logo.png' em 'app.ico' com redimensionamento premium (256x256)..." -ForegroundColor Gray
            Add-Type -AssemblyName System.Drawing
            
            $srcBmp = [System.Drawing.Image]::FromFile("logo.png")
            
            # Cria um bitmap de 256x256 pixels de alta qualidade
            $destBmp = New-Object System.Drawing.Bitmap(256, 256)
            $g = [System.Drawing.Graphics]::FromImage($destBmp)
            
            # Configurações premium de renderização
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            
            # Limpa o fundo com transparência
            $g.Clear([System.Drawing.Color]::Transparent)
            
            # Desenha a imagem original redimensionada para 256x256
            $g.DrawImage($srcBmp, 0, 0, 256, 256)
            
            # Salva o bitmap de destino como PNG em memória
            $ms = New-Object System.IO.MemoryStream
            $destBmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
            $pngBytes = $ms.ToArray()
            
            # Libera recursos gráficos
            $ms.Close()
            $g.Dispose()
            $destBmp.Dispose()
            $srcBmp.Dispose()
            
            # Grava a estrutura de arquivo ICO com o PNG de 256x256 encapsulado
            $icoFile = "app.ico"
            $fs = New-Object System.IO.FileStream($icoFile, [System.IO.FileMode]::Create)
            $w = New-Object System.IO.BinaryWriter($fs)
            
            # 1. Cabeçalho ICO (6 bytes)
            $w.Write([UInt16]0)          # Reservado: 0
            $w.Write([UInt16]1)          # Tipo: 1 (Ícone)
            $w.Write([UInt16]1)          # Quantidade de imagens: 1
            
            # 2. Diretório do Ícone (16 bytes)
            $w.Write([Byte]0)            # Largura: 256 (0 significa 256)
            $w.Write([Byte]0)            # Altura: 256 (0 significa 256)
            $w.Write([Byte]0)            # Quantidade de cores: 0 (sem paleta)
            $w.Write([Byte]0)            # Reservado: 0
            $w.Write([UInt16]1)          # Planos de cores: 1
            $w.Write([UInt16]32)         # Bits por pixel: 32
            $w.Write([UInt32]$pngBytes.Length) # Tamanho da imagem
            $w.Write([UInt32]22)         # Offset da imagem (6 bytes de cabeçalho + 16 de diretório)
            
            # 3. Dados da Imagem (PNG bruto)
            $w.Write($pngBytes)
            
            $w.Close()
            $fs.Close()
            
            Write-Host "-> 'app.ico' gerado com sucesso com cabeçalhos Win32 e formato 256x256 PNG!" -ForegroundColor Green
        } catch {
            Write-Host "[ALERTA] Falha ao converter imagem para ícone: $_" -ForegroundColor Yellow
        }
} else {
    Write-Host "[ALERTA] Logotipo do projeto (logo.png) não encontrado. A compilação continuará usando o ícone padrão do Windows." -ForegroundColor Yellow
}

# 2. CÓDIGO-FONTE C# DO LAUNCHER
$csharpSource = @"
using System;
using System.Diagnostics;
using System.Security.Principal;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

namespace DjiStreamHub
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            try
            {
                if (!IsAdministrator())
                {
                    // Se não for administrador, reinicia elevando privilégios (UAC prompt)
                    ProcessStartInfo restartInfo = new ProcessStartInfo();
                    restartInfo.FileName = Application.ExecutablePath;
                    restartInfo.UseShellExecute = true;
                    restartInfo.Verb = "runas";

                    Process.Start(restartInfo);
                    return;
                }

                // Diretório atual do executável
                string baseDir = AppDomain.CurrentDomain.BaseDirectory;

                // Lista de arquivos vitais a serem extraídos se não existirem (Modelo Híbrido Autônomo)
                string[] filesToExtract = new string[] {
                    "start-stream.ps1",
                    "dashboard.html",
                    "mediamtx_template.yml",
                    "logo.png",
                    "app.ico"
                };

                foreach (string fileName in filesToExtract)
                {
                    string outputPath = Path.Combine(baseDir, fileName);
                    try
                    {
                        // Sempre extrai e sobrescreve para garantir que os arquivos estejam sempre atualizados com o executável
                        ExtractResource(fileName, outputPath);
                    }
                    catch (Exception ex)
                    {
                        // Se por algum motivo o arquivo estiver bloqueado, registra mas não interrompe a inicialização
                        Console.WriteLine("Erro ao extrair " + fileName + ": " + ex.Message);
                    }
                }

                // Executa o script PowerShell extraído
                string scriptPath = Path.Combine(baseDir, "start-stream.ps1");
                
                if (!File.Exists(scriptPath))
                {
                    MessageBox.Show(
                        "Erro Crítico: O script 'start-stream.ps1' não pôde ser extraído.",
                        "Erro de Inicialização",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error
                    );
                    return;
                }

                ProcessStartInfo psInfo = new ProcessStartInfo();
                psInfo.FileName = "powershell.exe";
                psInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + scriptPath + "\"";
                psInfo.UseShellExecute = false;
                psInfo.CreateNoWindow = false;

                Process psProcess = Process.Start(psInfo);
                if (psProcess != null)
                {
                    psProcess.WaitForExit();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "Ocorreu um erro ao tentar descompactar ou executar o iniciador:\n\n" + ex.Message,
                    "Erro Crítico",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
            }
        }

        private static bool IsAdministrator()
        {
            WindowsIdentity identity = WindowsIdentity.GetCurrent();
            WindowsPrincipal principal = new WindowsPrincipal(identity);
            return principal.IsInRole(WindowsBuiltInRole.Administrator);
        }

        private static string FindResourceName(string fileName)
        {
            Assembly assembly = Assembly.GetExecutingAssembly();
            foreach (string name in assembly.GetManifestResourceNames())
            {
                if (name.EndsWith(fileName, StringComparison.OrdinalIgnoreCase))
                {
                    return name;
                }
            }
            return null;
        }

        private static void ExtractResource(string fileName, string outputPath)
        {
            string resourceName = FindResourceName(fileName);
            if (string.IsNullOrEmpty(resourceName))
            {
                throw new Exception("Recurso não encontrado no executável: " + fileName);
            }
            
            Assembly assembly = Assembly.GetExecutingAssembly();
            using (Stream stream = assembly.GetManifestResourceStream(resourceName))
            {
                if (stream == null)
                {
                    throw new Exception("Falha ao ler o fluxo de dados do recurso: " + resourceName);
                }
                using (FileStream fileStream = new FileStream(outputPath, FileMode.Create, FileAccess.Write))
                {
                    stream.CopyTo(fileStream);
                }
            }
        }
    }
}
"@

# 3. LOCALIZAR O COMPILADOR CSC.EXE DO .NET FRAMEWORK
Write-Host "`nProcurando compilador C# nativo (csc.exe)..." -ForegroundColor Gray

$cscPaths = @(
    "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)

$cscPath = $null
foreach ($path in $cscPaths) {
    if (Test-Path $path) {
        $cscPath = $path
        break
    }
}

if ($null -eq $cscPath) {
    Write-Host "[ERRO] Não foi possível encontrar o compilador 'csc.exe' do .NET Framework no Windows!" -ForegroundColor Red
    Write-Host "Verifique se o .NET Framework está ativado em Recursos do Windows." -ForegroundColor Red
    Read-Host "Pressione Enter para sair..."
    exit
}

Write-Host "-> Compilador encontrado em: $cscPath" -ForegroundColor Green

# 4. ESCREVER CÓDIGO-FONTE TEMPORÁRIO
$tempSourceFile = "LauncherTemp.cs"
Write-Host "Gerando arquivo de código-fonte temporário..." -ForegroundColor Gray
$csharpSource | Out-File -FilePath $tempSourceFile -Encoding utf8 -Force

# 5. COMPILAR O EXECUTÁVEL
$outputExe = "DJI-Stream-Hub.exe"
Write-Host "Compilando executável nativo com ícone personalizado '$outputExe'..." -ForegroundColor Gray

# Argumentos do Compilador
$compilerArgs = @("/target:winexe", "/out:$outputExe", "/reference:System.Windows.Forms.dll")
if (Test-Path "app.ico") {
    $compilerArgs += "/win32icon:app.ico"
    Write-Host "-> Incluindo ícone personalizado 'app.ico' na compilação." -ForegroundColor Green
}

# Incluir recursos embutidos para o modelo autônomo (Abordagem A)
$resourcesToEmbed = @(
    "start-stream.ps1",
    "dashboard.html",
    "mediamtx_template.yml",
    "logo.png",
    "app.ico"
)

foreach ($res in $resourcesToEmbed) {
    if (Test-Path $res) {
        $compilerArgs += "/resource:$res"
        Write-Host "-> Embutindo recurso para auto-extração: $res" -ForegroundColor Green
    }
}

$compilerArgs += $tempSourceFile

# Executa o compilador
& $cscPath $compilerArgs

# 6. VERIFICAÇÃO DE SUCESSO
if (Test-Path $outputExe) {
    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "          COMPILAÇÃO CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  -> O arquivo '$outputExe' foi gerado!" -ForegroundColor White
    if (Test-Path "app.ico") {
        Write-Host "  -> Logotipo personalizado incorporado como ícone do .EXE!" -ForegroundColor Green
    }
    Write-Host "  -> Ele solicitará UAC automaticamente ao ser aberto." -ForegroundColor White
    Write-Host "  -> Executará o script 'start-stream.ps1' com privilégios." -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
} else {
    Write-Host "[ERRO] A compilação falhou! Verifique as mensagens do compilador acima." -ForegroundColor Red
}

# 7. LIMPEZA DOS TEMPORÁRIOS
if (Test-Path $tempSourceFile) {
    Write-Host "Limpando arquivos temporários..." -ForegroundColor Gray
    Remove-Item $tempSourceFile -Force
}

Write-Host "Finalizado." -ForegroundColor Gray
Start-Sleep -Seconds 2
