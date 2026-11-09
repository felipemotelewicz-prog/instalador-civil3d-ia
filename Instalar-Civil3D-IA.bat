<# : parte do Windows (nao mexer nesta linha)
@echo off
chcp 65001 >nul
title Instalador - Claude no Civil 3D
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%~f0'; iex ([IO.File]::ReadAllText($f))"
echo.
pause
exit /b
#>

# ============================================================
#  Instalador: liga o Claude Desktop no AutoCAD / Civil 3D
#  (AutoCAD MCP Pro, canal COM). Roda sem pedir administrador.
# ============================================================
$ErrorActionPreference = 'Continue'
$log = Join-Path $env:TEMP 'instalador-civil3d-ia.log'
try { Start-Transcript -Path $log -Force | Out-Null } catch {}

function Passo($n, $txt) { Write-Host ""; Write-Host "[$n/6] $txt" -ForegroundColor Cyan }
function Ok($txt)   { Write-Host "   OK  $txt" -ForegroundColor Green }
function Aviso($txt){ Write-Host "   !!  $txt" -ForegroundColor Yellow }
function Falha($txt){
    Write-Host ""; Write-Host "   ERRO: $txt" -ForegroundColor Red
    Write-Host "   Mande este arquivo para o suporte: $log" -ForegroundColor Red
    try { Stop-Transcript | Out-Null } catch {}
    exit 1
}
function Atualiza-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
}

Write-Host "=============================================" -ForegroundColor White
Write-Host "   Claude + Civil 3D  -  instalador" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor White

# ---------- 1. AutoCAD / Civil 3D instalado? ----------
Passo 1 "Procurando AutoCAD / Civil 3D neste computador"
$produtos = @()
foreach ($raiz in 'HKLM:\SOFTWARE\Autodesk\AutoCAD','HKCU:\SOFTWARE\Autodesk\AutoCAD') {
    if (Test-Path $raiz) {
        Get-ChildItem $raiz -ErrorAction SilentlyContinue | ForEach-Object {
            Get-ChildItem $_.PSPath -ErrorAction SilentlyContinue | ForEach-Object {
                $nome = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).ProductName
                if ($nome) { $produtos += $nome }
            }
        }
    }
}
$produtos = $produtos | Sort-Object -Unique
if ($produtos) { $produtos | ForEach-Object { Ok $_ } } else { Aviso "Nao achei pelo registro. Se o Civil 3D estiver instalado, pode seguir." }
if ($produtos -and -not ($produtos | Where-Object { $_ -notmatch '\bLT\b' })) {
    Aviso "So achei AutoCAD LT. O LT NAO aceita controle externo - precisa do AutoCAD completo ou Civil 3D."
}

# ---------- 2. Python 3.11+ ----------
Passo 2 "Conferindo o Python (precisa 3.11 ou mais novo)"
function Acha-Python {
    $cands = @()
    if (Get-Command py -ErrorAction SilentlyContinue) { $cands += ,@('py','-3') }
    if (Get-Command python -ErrorAction SilentlyContinue) { $cands += ,@('python') }
    foreach ($v in '314','313','312','311') {
        foreach ($base in "$env:LOCALAPPDATA\Programs\Python\Python$v","$env:ProgramFiles\Python$v") {
            if (Test-Path "$base\python.exe") { $cands += ,@("$base\python.exe") }
        }
    }
    foreach ($c in $cands) {
        try {
            $exe = $c[0]; $extra = @($c | Select-Object -Skip 1)
            $out = & $exe @extra -c "import sys;print(sys.executable if sys.version_info>=(3,11) else '')" 2>$null
            if ($LASTEXITCODE -eq 0 -and $out -and (Test-Path $out.Trim())) { return $out.Trim() }
        } catch {}
    }
    return $null
}
$py = Acha-Python
if (-not $py) {
    Aviso "Python nao encontrado. Instalando o Python 3.12 (pode levar uns minutos)..."
    $instalou = $false
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            winget install -e --id Python.Python.3.12 --scope user --silent --accept-package-agreements --accept-source-agreements | Out-Host
            $instalou = $true
        } catch { Aviso "winget falhou, tentando baixar direto do python.org" }
    }
    Atualiza-Path; $py = Acha-Python
    if (-not $py) {
        $url = 'https://www.python.org/ftp/python/3.12.8/python-3.12.8-amd64.exe'
        $setup = Join-Path $env:TEMP 'python-setup.exe'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        try { Invoke-WebRequest -Uri $url -OutFile $setup -UseBasicParsing -ErrorAction Stop } catch { Falha "Nao consegui baixar o Python. Confira a internet." }
        Start-Process $setup -ArgumentList '/quiet','InstallAllUsers=0','PrependPath=1','Include_launcher=1' -Wait
        Atualiza-Path; $py = Acha-Python
    }
    if (-not $py) { Falha "Nao consegui instalar o Python. Instale em python.org (marque 'Add python.exe to PATH') e rode de novo." }
}
Ok "Python: $py"

# ---------- 3. Instalar o AutoCAD MCP ----------
Passo 3 "Instalando a conexao (AutoCAD MCP Pro)"
# Se o Claude estiver usando o programa, o pip nao consegue atualizar: fecha antes.
Get-Process autocad-mcp, autocad-mcp-pro -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
& $py -m pip install --upgrade pip --quiet --disable-pip-version-check 2>&1 | Out-Host
& $py -m pip install --upgrade "autocad-mcp-pro[full]" pywin32 --disable-pip-version-check 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) {
    Aviso "Tentando de novo so para este usuario..."
    & $py -m pip install --user --upgrade "autocad-mcp-pro[full]" pywin32 --disable-pip-version-check 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) { Falha "O pip nao conseguiu instalar o autocad-mcp-pro." }
}
$exe = & $py -c "import sysconfig,os;c=[os.path.join(sysconfig.get_path('scripts',s),'autocad-mcp.exe') for s in (None,os.name+'_user')];print(next((p for p in c if os.path.exists(p)),''))"
$exe = "$exe".Trim()
if (-not $exe -or -not (Test-Path $exe)) { Falha "Instalou, mas nao achei o autocad-mcp.exe." }
Ok "Programa: $exe"

# ---------- 4. Fechar o Claude Desktop ----------
Passo 4 "Fechando o Claude Desktop (ele so le a configuracao quando abre)"
$claudeDesk = Get-Process claude -ErrorAction SilentlyContinue | Where-Object { $_.Path -match 'WindowsApps\\Claude_|AnthropicClaude|\\Programs\\Claude' }
$caminhoClaude = ($claudeDesk | Select-Object -First 1).Path
if ($claudeDesk) { $claudeDesk | Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2; Ok "Claude fechado" } else { Ok "Claude ja estava fechado" }

# ---------- 5. Gravar a configuracao ----------
Passo 5 "Gravando a configuracao do Claude"
$pastas = @()
$pastas += Get-ChildItem "$env:LOCALAPPDATA\Packages" -Directory -Filter 'Claude_*' -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName 'LocalCache\Roaming\Claude' } | Where-Object { Test-Path $_ }
$pastas += Get-ChildItem "$env:LOCALAPPDATA\Claude-Data" -Directory -Filter 'claude_*' -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
if (Test-Path "$env:APPDATA\Claude") { $pastas += "$env:APPDATA\Claude" }
if (-not $pastas) { New-Item -ItemType Directory -Force "$env:APPDATA\Claude" | Out-Null; $pastas = @("$env:APPDATA\Claude") }

$permitidas = @(
    [Environment]::GetFolderPath('MyDocuments'),
    [Environment]::GetFolderPath('Desktop'),
    (Join-Path $env:USERPROFILE 'Downloads')
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

$servidor = [pscustomobject]@{
    command = $exe
    env     = [pscustomobject]@{
        AUTOCAD_MCP_BACKEND = 'com'
        ALLOWED_PATHS       = ($permitidas -join ',')
    }
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
$gravou = 0
foreach ($p in ($pastas | Select-Object -Unique)) {
    $arq = Join-Path $p 'claude_desktop_config.json'
    $cfg = $null
    if (Test-Path $arq) {
        Copy-Item $arq "$arq.bak-$(Get-Date -Format yyyyMMdd-HHmmss)" -Force
        $txt = [IO.File]::ReadAllText($arq)
        if ($txt.Trim()) {
            try { $cfg = $txt | ConvertFrom-Json -ErrorAction Stop }
            catch { Aviso "Config com erro de digitacao em $arq - nao mexi nele (copia de seguranca feita)."; continue }
        }
    }
    if (-not $cfg) { $cfg = [pscustomobject]@{} }
    if (-not ($cfg.PSObject.Properties.Name -contains 'mcpServers') -or -not $cfg.mcpServers) {
        $cfg | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    $cfg.mcpServers.PSObject.Properties.Remove('autocad')
    $cfg.mcpServers | Add-Member -NotePropertyName autocad -NotePropertyValue $servidor -Force
    [IO.File]::WriteAllText($arq, ($cfg | ConvertTo-Json -Depth 50), $utf8)
    Ok "Gravado em $arq"
    $gravou++
}
if ($gravou -eq 0) { Falha "Nao consegui gravar nenhuma configuracao." }
Ok "Pastas liberadas para abrir/salvar desenhos: $($permitidas -join ' | ')"

# ---------- 6. Abrir de novo ----------
Passo 6 "Quase pronto"
Write-Host ""
Write-Host "   1) ABRA O CIVIL 3D com um desenho qualquer." -ForegroundColor White
Write-Host "   2) Depois aperte ENTER aqui para eu abrir o Claude." -ForegroundColor White
Read-Host "   ENTER para continuar" | Out-Null
try {
    if ($caminhoClaude -and $caminhoClaude -notmatch 'WindowsApps') { Start-Process $caminhoClaude }
    elseif (Get-AppxPackage -Name 'Claude' -ErrorAction SilentlyContinue) { Start-Process 'explorer.exe' 'shell:AppsFolder\Claude_pzs8sxrjxfjjc!Claude' }
    elseif (Test-Path "$env:LOCALAPPDATA\AnthropicClaude\claude.exe") { Start-Process "$env:LOCALAPPDATA\AnthropicClaude\claude.exe" }
    else { Aviso "Abra o Claude pelo menu Iniciar." }
} catch { Aviso "Abra o Claude pelo menu Iniciar." }

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "   PRONTO!" -ForegroundColor Green
Write-Host "   No Claude, escreva:  use o system_status do autocad" -ForegroundColor Green
Write-Host "   Tem que aparecer 'connected: true' com o nome do seu desenho." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host "   Deu erro? Mande este arquivo: $log"
try { Stop-Transcript | Out-Null } catch {}
