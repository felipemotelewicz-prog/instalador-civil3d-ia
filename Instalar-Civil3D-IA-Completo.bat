<# : parte do Windows (nao mexer nesta linha)
@echo off
chcp 65001 >nul
title Instalador - Claude no Civil 3D (completo)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%~f0'; iex ([IO.File]::ReadAllText($f))"
echo.
pause
exit /b
#>

# =====================================================================
#  Instalador COMPLETO: liga o Claude Desktop nos objetos do Civil 3D
#  (superficies, alinhamentos, perfis, corredores, redes, pontos...)
#  Servidor: Civil3D-mcp (SimsUDS, licenca MIT) + plugin compilado aqui.
#  Nao pede login. Nao pede administrador.
# =====================================================================
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$VERSAO     = '2.0.0'
$BASE_URL   = 'https://github.com/felipemotelewicz-prog/instalador-civil3d-ia/releases/download/v2.0.0'
$PARTES     = @('servidor.zip.part0','servidor.zip.part1','servidor.zip.part2')
$SHA_ZIP    = '0309db64952a54d38fad62d49e553a1afb4ed6416f2b11be252493561fb7c664'
$NODE_VER   = 'v22.12.0'
$PORTA      = 8091   # porta do plugin (a 8080 fica livre para o Revit MCP)
$PORTA_HTTP = 3091

$RAIZ   = Join-Path $env:LOCALAPPDATA 'Civil3D-IA'
$BUNDLE = Join-Path $env:APPDATA 'Autodesk\ApplicationPlugins\Civil3DIA.bundle'
New-Item -ItemType Directory -Force $RAIZ | Out-Null
$log = Join-Path $env:TEMP 'instalador-civil3d-ia.log'
try { Start-Transcript -Path $log -Force | Out-Null } catch {}

function Passo($n, $txt) { Write-Host ""; Write-Host "[$n/8] $txt" -ForegroundColor Cyan }
function Ok($txt)   { Write-Host "   OK  $txt" -ForegroundColor Green }
function Aviso($txt){ Write-Host "   !!  $txt" -ForegroundColor Yellow }
function Falha($txt){
    Write-Host ""; Write-Host "   ERRO: $txt" -ForegroundColor Red
    Write-Host "   Mande este arquivo para o suporte: $log" -ForegroundColor Red
    try { Stop-Transcript | Out-Null } catch {}
    exit 1
}
function Baixa($url, $destino) {
    for ($i = 1; $i -le 3; $i++) {
        try { Invoke-WebRequest -Uri $url -OutFile $destino -UseBasicParsing -ErrorAction Stop; return $true }
        catch { Aviso "Falhou o download (tentativa $i de 3): $url"; Start-Sleep -Seconds 3 }
    }
    return $false
}

Write-Host "=====================================================" -ForegroundColor White
Write-Host "   Claude + Civil 3D (completo)  -  instalador $VERSAO" -ForegroundColor White
Write-Host "   Versao beta" -ForegroundColor White
Write-Host "=====================================================" -ForegroundColor White

# ---------- 1. Achar o Civil 3D ----------
Passo 1 "Procurando o Civil 3D"
$civis = @()
foreach ($r in Get-ChildItem 'HKLM:\SOFTWARE\Autodesk\AutoCAD' -ErrorAction SilentlyContinue) {
    foreach ($p in Get-ChildItem $r.PSPath -ErrorAction SilentlyContinue) {
        $prop = Get-ItemProperty $p.PSPath -ErrorAction SilentlyContinue
        if ($prop.ProductName -match 'Civil 3D' -and $prop.AcadLocation -and (Test-Path (Join-Path $prop.AcadLocation 'C3D\AeccDbMgd.dll'))) {
            $ano = [regex]::Match($prop.ProductName + ' ' + $prop.AcadLocation, '20\d\d').Value
            $civis += [pscustomobject]@{ Ano = [int]$ano; Serie = $r.PSChildName; Pasta = $prop.AcadLocation.TrimEnd('\'); Nome = $prop.ProductName }
        }
    }
}
if (-not $civis) {
    # plano B: procurar a pasta direto
    $mapa = @{ 2025 = 'R25.0'; 2026 = 'R25.1'; 2027 = 'R26.0' }
    foreach ($d in Get-ChildItem "$env:ProgramFiles\Autodesk" -Directory -Filter 'AutoCAD 20*' -ErrorAction SilentlyContinue) {
        if (Test-Path (Join-Path $d.FullName 'C3D\AeccDbMgd.dll')) {
            $ano = [int]([regex]::Match($d.Name, '20\d\d').Value)
            $civis += [pscustomobject]@{ Ano = $ano; Serie = $mapa[$ano]; Pasta = $d.FullName; Nome = "Civil 3D $ano" }
        }
    }
}
$civis = $civis | Sort-Object Ano -Unique
if (-not $civis) { Falha "Nao achei o Civil 3D neste computador." }
$civis | ForEach-Object { Ok "$($_.Nome)  ($($_.Pasta))" }

$validos = @()
foreach ($c in $civis) {
    if ($c.Ano -lt 2025) { Aviso "$($c.Nome): versao antiga demais para esta conexao (precisa 2025 ou mais novo). Vou pular."; continue }
    if (-not $c.Serie)   { Aviso "$($c.Nome): nao consegui identificar a versao interna. Vou pular."; continue }
    # Descobrir se esse Civil 3D roda em .NET 8 ou .NET 10 (lendo a DLL dele)
    $bytes = [IO.File]::ReadAllBytes((Join-Path $c.Pasta 'acdbmgd.dll'))
    $txt = [Text.Encoding]::ASCII.GetString($bytes)
    $net = if ($txt.Contains('.NETCoreApp,Version=v10.0')) { 'net10.0-windows' } elseif ($txt.Contains('.NETCoreApp,Version=v8.0')) { 'net8.0-windows' } else { $null }
    if (-not $net) { Aviso "$($c.Nome): nao reconheci a versao do .NET. Vou pular."; continue }
    $c | Add-Member -NotePropertyName Net -NotePropertyValue $net -Force
    if ($c.Ano -ne 2026) { Aviso "$($c.Nome): a conexao foi validada pelo autor so no 2026. Deve funcionar, mas e beta." }
    $validos += $c
}
if (-not $validos) { Falha "Nenhum Civil 3D compativel (2025, 2026 ou 2027)." }

# Civil 3D precisa estar fechado para trocar o plugin
while (Get-Process acad -ErrorAction SilentlyContinue) {
    if ($env:C3D_GUI -eq '1') { Falha "O Civil 3D esta aberto. Feche o programa e clique em Instalar de novo." }
    Aviso "O Civil 3D / AutoCAD esta aberto. Salve seus desenhos e FECHE o programa."
    Read-Host "   Depois de fechar, aperte ENTER" | Out-Null
}

# ---------- 2. Node.js ----------
Passo 2 "Conferindo o Node.js"
$node = $null
$nodeLocal = Join-Path $RAIZ "node\node.exe"
foreach ($cand in @($nodeLocal, (Get-Command node -ErrorAction SilentlyContinue).Source)) {
    if ($cand -and (Test-Path $cand)) {
        $v = (& $cand -v 2>$null) -replace '^v',''
        if ($v -and ([version]$v -ge [version]'18.17.0')) { $node = $cand; break }
    }
}
if (-not $node) {
    Aviso "Baixando o Node.js $NODE_VER (so para esta conexao)..."
    $zipNode = Join-Path $env:TEMP "node-$NODE_VER.zip"
    if (-not (Baixa "https://nodejs.org/dist/$NODE_VER/node-$NODE_VER-win-x64.zip" $zipNode)) { Falha "Nao consegui baixar o Node.js." }
    $tmpNode = Join-Path $RAIZ 'node-tmp'
    Remove-Item $tmpNode, (Join-Path $RAIZ 'node') -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive $zipNode -DestinationPath $tmpNode -Force
    Move-Item (Get-ChildItem $tmpNode -Directory | Select-Object -First 1).FullName (Join-Path $RAIZ 'node')
    Remove-Item $tmpNode -Recurse -Force -ErrorAction SilentlyContinue
    $node = $nodeLocal
}
if (-not (Test-Path $node)) { Falha "Node.js nao ficou instalado." }
Ok "Node: $node"

# ---------- 3. .NET SDK (para compilar o plugin aqui mesmo) ----------
Passo 3 "Conferindo o .NET SDK (usado para montar o plugin do Civil 3D)"
$precisa = if ($validos | Where-Object { $_.Net -like 'net10*' }) { 10 } else { 8 }
$dotnet = $null
$dotLocal = Join-Path $RAIZ 'dotnet\dotnet.exe'
foreach ($cand in @($dotLocal, (Get-Command dotnet -ErrorAction SilentlyContinue).Source)) {
    if ($cand -and (Test-Path $cand)) {
        $sdks = & $cand --list-sdks 2>$null
        if ($sdks | Where-Object { $_ -match '^(\d+)\.' -and [int]$Matches[1] -ge $precisa }) { $dotnet = $cand; break }
    }
}
if (-not $dotnet) {
    Aviso "Baixando o .NET SDK $precisa (pode levar alguns minutos)..."
    $script = Join-Path $env:TEMP 'dotnet-install.ps1'
    if (-not (Baixa 'https://dot.net/v1/dotnet-install.ps1' $script)) { Falha "Nao consegui baixar o instalador do .NET." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $script -Channel "$precisa.0" -InstallDir (Join-Path $RAIZ 'dotnet') -NoPath | Out-Host
    $dotnet = $dotLocal
}
if (-not (Test-Path $dotnet)) { Falha ".NET SDK nao ficou instalado." }
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'; $env:DOTNET_NOLOGO = '1'
Ok ".NET: $dotnet"

# ---------- 4. Baixar a conexao ----------
Passo 4 "Baixando a conexao do Civil 3D (180+ ferramentas)"
$zip = Join-Path $env:TEMP 'civil3d-ia-servidor.zip'
$saida = [IO.File]::Create($zip)
try {
    foreach ($p in $PARTES) {
        $tmp = Join-Path $env:TEMP $p
        if (-not (Baixa "$BASE_URL/$p" $tmp)) { $saida.Close(); Falha "Nao consegui baixar $p." }
        $b = [IO.File]::ReadAllBytes($tmp); $saida.Write($b, 0, $b.Length); Remove-Item $tmp -Force
    }
} finally { $saida.Close() }
$hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
if ($hash -ne $SHA_ZIP) { Falha "O arquivo baixado veio corrompido (assinatura nao bate)." }
$srv = Join-Path $RAIZ 'civil3d-mcp'
Get-Process node -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$RAIZ*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Remove-Item $srv -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive $zip -DestinationPath $RAIZ -Force
Remove-Item $zip -Force
$index = Join-Path $srv 'build\index.js'
if (-not (Test-Path $index)) { Falha "A conexao nao foi extraida direito." }
Ok "Conexao em: $srv"

# ---------- 5. Montar o plugin para cada Civil 3D ----------
Passo 5 "Montando o plugin para o seu Civil 3D"
$fonte = Join-Path $srv 'plugin-src\Civil3D-MCP-Plugin'
Remove-Item (Join-Path $BUNDLE 'Contents') -Recurse -Force -ErrorAction SilentlyContinue
$montados = @()
foreach ($c in $validos) {
    Write-Host "   Montando para $($c.Nome) ($($c.Net))..."
    $refs = Join-Path $RAIZ "refs\$($c.Ano)"
    New-Item -ItemType Directory -Force $refs | Out-Null
    $arqs = @{ 'accoremgd.dll' = ''; 'acdbmgd.dll' = ''; 'acmgd.dll' = ''; 'AecBaseMgd.dll' = 'ACA'; 'AeccDbMgd.dll' = 'C3D'; 'AeccPressurePipesMgd.dll' = 'C3D' }
    $faltou = $false
    foreach ($a in $arqs.Keys) {
        $origem = Join-Path (Join-Path $c.Pasta $arqs[$a]) $a
        if (-not (Test-Path $origem)) { $origem = Get-ChildItem $c.Pasta -Recurse -Filter $a -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
        if (-not $origem) { Aviso "Nao achei $a"; $faltou = $true; continue }
        Copy-Item $origem (Join-Path $refs $a) -Force
    }
    if ($faltou) { Aviso "Pulando $($c.Nome): faltam arquivos do Civil 3D."; continue }

    $obra = Join-Path $RAIZ "obra\$($c.Ano)"
    Remove-Item $obra -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item $fonte $obra -Recurse
    $csproj = Join-Path $obra 'Civil3DMcpPlugin.csproj'
    $xml = [IO.File]::ReadAllText($csproj) -replace '<TargetFramework>[^<]+</TargetFramework>', "<TargetFramework>$($c.Net)</TargetFramework>"
    [IO.File]::WriteAllText($csproj, $xml)

    $destino = Join-Path $BUNDLE "Contents\$($c.Ano)"
    & $dotnet build $csproj -c Release "-p:Civil3DReferencesPath=$refs" -o $destino --nologo -v minimal 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $destino 'Civil3DMcpPlugin.dll'))) { Aviso "Nao consegui montar o plugin para $($c.Nome)."; continue }
    # nao levar copias das DLLs da Autodesk junto
    $arqs.Keys | ForEach-Object { Remove-Item (Join-Path $destino $_) -Force -ErrorAction SilentlyContinue }
    $montados += $c
    Ok "Plugin pronto para $($c.Nome)"
}
if (-not $montados) { Falha "Nao consegui montar o plugin para nenhum Civil 3D." }

# ---------- 6. Carregar sozinho quando o Civil 3D abrir ----------
Passo 6 "Fazendo o plugin abrir sozinho junto com o Civil 3D"
$comp = ($montados | ForEach-Object {
@"
  <Components Description="Civil 3D $($_.Ano)">
    <RuntimeRequirements OS="Win64" Platform="Civil3D" SeriesMin="$($_.Serie)" SeriesMax="$($_.Serie)" />
    <ComponentEntry AppName="Civil3DIA" Version="$VERSAO" ModuleName="./Contents/$($_.Ano)/Civil3DMcpPlugin.dll" AppDescription="Conexao do Claude com o Civil 3D" LoadOnAutoCADStartup="True" />
  </Components>
"@ }) -join "`r`n"
$pc = @"
<?xml version="1.0" encoding="utf-8"?>
<ApplicationPackage SchemaVersion="1.0" AutodeskProduct="AutoCAD" ProductType="Application" Name="Civil3D IA" AppVersion="$VERSAO" Description="Conexao do Claude com o Civil 3D" Author="AutoRevit" ProductCode="{6B1D4E2A-9C3F-4E7B-8A51-2F0C7D9E3B14}" UpgradeCode="{A3E5C7D9-1B2F-4A6C-9E8D-5F7B3C1A2E60}">
  <CompanyDetails Name="AutoRevit" />
$comp
</ApplicationPackage>
"@
[IO.File]::WriteAllText((Join-Path $BUNDLE 'PackageContents.xml'), $pc, (New-Object System.Text.UTF8Encoding($false)))
[Environment]::SetEnvironmentVariable('CIVIL3D_MCP_PORT', "$PORTA", 'User')
Ok "Plugin registrado em $BUNDLE (porta $PORTA)"

# ---------- 7. Configuracao do Claude ----------
Passo 7 "Gravando a configuracao do Claude"
$claudeDesk = Get-Process claude -ErrorAction SilentlyContinue | Where-Object { $_.Path -match 'WindowsApps\\Claude_|AnthropicClaude|\\Programs\\Claude' }
$caminhoClaude = ($claudeDesk | Select-Object -First 1).Path
if ($claudeDesk) { $claudeDesk | Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2; Ok "Claude fechado" }

$pastas = @()
$pastas += Get-ChildItem "$env:LOCALAPPDATA\Packages" -Directory -Filter 'Claude_*' -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName 'LocalCache\Roaming\Claude' } | Where-Object { Test-Path $_ }
$pastas += Get-ChildItem "$env:LOCALAPPDATA\Claude-Data" -Directory -Filter 'claude_*' -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
if (Test-Path "$env:APPDATA\Claude") { $pastas += "$env:APPDATA\Claude" }
if (-not $pastas) { New-Item -ItemType Directory -Force "$env:APPDATA\Claude" | Out-Null; $pastas = @("$env:APPDATA\Claude") }

$servidor = [pscustomobject]@{
    command = $node
    args    = @($index)
    env     = [pscustomobject]@{
        CIVIL3D_HOST  = '127.0.0.1'
        CIVIL3D_PORT  = "$PORTA"
        MCP_HTTP_PORT = "$PORTA_HTTP"
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
    $cfg.mcpServers.PSObject.Properties.Remove('civil3d')
    $cfg.mcpServers | Add-Member -NotePropertyName civil3d -NotePropertyValue $servidor -Force
    [IO.File]::WriteAllText($arq, ($cfg | ConvertTo-Json -Depth 50), $utf8)
    Ok "Gravado em $arq"
    $gravou++
}
if ($gravou -eq 0) { Falha "Nao consegui gravar nenhuma configuracao do Claude." }

# ---------- 8. Abrir ----------
Passo 8 "Quase pronto"
Write-Host ""
if ($env:C3D_GUI -eq '1') { Write-Host "##CLAUDE##$caminhoClaude" } else {
Write-Host "   1) ABRA O CIVIL 3D com um desenho." -ForegroundColor White
Write-Host "      Se aparecer um aviso de seguranca sobre 'Civil3DMcpPlugin', clique em 'Sempre carregar'." -ForegroundColor White
Write-Host "      Na linha de comando deve aparecer: Civil3D MCP plugin initialized on port $PORTA" -ForegroundColor White
Write-Host "   2) Depois aperte ENTER aqui para eu abrir o Claude." -ForegroundColor White
Read-Host "   ENTER para continuar" | Out-Null
try {
    if ($caminhoClaude -and $caminhoClaude -notmatch 'WindowsApps') { Start-Process $caminhoClaude }
    elseif (Get-AppxPackage -Name 'Claude' -ErrorAction SilentlyContinue) { Start-Process 'explorer.exe' 'shell:AppsFolder\Claude_pzs8sxrjxfjjc!Claude' }
    elseif (Test-Path "$env:LOCALAPPDATA\AnthropicClaude\claude.exe") { Start-Process "$env:LOCALAPPDATA\AnthropicClaude\claude.exe" }
    else { Aviso "Abra o Claude pelo menu Iniciar." }
} catch { Aviso "Abra o Claude pelo menu Iniciar." }

}
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "   PRONTO!" -ForegroundColor Green
Write-Host "   No Claude, escreva:  use o civil3d_health" -ForegroundColor Green
Write-Host "   Tem que aparecer o Civil 3D conectado e o nome do desenho." -ForegroundColor Green
Write-Host "   No Civil 3D, o comando C3DMCPSTATUS mostra se o plugin esta rodando." -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "   Deu erro? Mande este arquivo: $log"
try { Stop-Transcript | Out-Null } catch {}
