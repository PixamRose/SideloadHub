#Requires -Version 5.1
param(
    [int]$Port = 8765,
    [string]$ConfigPath = "",
    [string]$OutputRoot = "",
    [switch]$SkipSync
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$serverVersion = "1.0.0"

if (-not $ConfigPath) { $ConfigPath = Join-Path $scriptDir "config\apps.json" }
if (-not $OutputRoot) { $OutputRoot = Join-Path $repoRoot "build-output" }

function Get-LocalIPv4 {
    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notmatch '^127\.' -and
            $_.IPAddress -notmatch '^169\.254\.' -and
            $_.PrefixOrigin -ne 'WellKnown'
        } |
        Sort-Object InterfaceMetric |
        Select-Object -ExpandProperty IPAddress -First 1
}

function Read-Config {
    if (-not (Test-Path $ConfigPath)) { throw "Config introuvable: $ConfigPath" }
    Get-Content $ConfigPath -Raw | ConvertFrom-Json
}

function Get-AppCatalog {
    param([object]$Config)

    $apps = @()
    foreach ($app in $Config.apps) {
        $appDir = Join-Path $OutputRoot $app.id
        $ipaPath = Join-Path $appDir $app.github.ipaFileName
        if (-not (Test-Path $ipaPath)) { continue }

        $file = Get-Item $ipaPath
        $meta = @{}
        $metaPath = Join-Path $appDir "meta.json"
        if (Test-Path $metaPath) {
            $meta = Get-Content $metaPath -Raw | ConvertFrom-Json
        }

        $entry = [ordered]@{
            id = $app.id
            name = $app.name
            bundleId = $app.bundleId
            icon = $app.icon
            accent = $app.accent
            version = if ($meta.version) { "$($meta.version)" } else { "?" }
            build = if ($meta.buildNumber) { "$($meta.buildNumber)" } else { "?" }
            sizeBytes = [int64]$file.Length
            updatedAt = $file.LastWriteTimeUtc.ToString("o")
            downloadPath = "/api/v1/apps/$($app.id)/download"
            webPath = "/apps/$($app.id)"
        }
        if ($meta.commit) { $entry.commit = "$($meta.commit)" }
        if ($meta.message) { $entry.message = "$($meta.message)" }
        $apps += $entry
    }
    return ,$apps
}

function ConvertTo-JsonArray {
    param(
        [array]$Items,
        [int]$Depth = 6
    )

    if (-not $Items -or $Items.Count -eq 0) {
        return "[]"
    }

    $parts = @()
    foreach ($item in $Items) {
        $parts += (ConvertTo-Json $item -Depth $Depth -Compress)
    }
    return "[" + ($parts -join ",") + "]"
}

function Get-JsonBody {
    param([object]$Data)
    $json = $Data | ConvertTo-Json -Depth 8 -Compress
    [System.Text.Encoding]::UTF8.GetBytes($json)
}

function Get-CatalogJsonBody {
    param(
        [array]$Catalog,
        [string]$BaseUrl
    )

    $serverJson = (@{
        name = "SideloadHub"
        version = $serverVersion
        baseUrl = $BaseUrl
    } | ConvertTo-Json -Compress)

    $appsJson = ConvertTo-JsonArray -Items $Catalog -Depth 8
    $json = "{`"server`":$serverJson,`"apps`":$appsJson}"
    [System.Text.Encoding]::UTF8.GetBytes($json)
}

function Send-HttpResponse {
    param(
        [System.Net.Sockets.NetworkStream]$Stream,
        [int]$StatusCode,
        [string]$StatusText,
        [string]$ContentType,
        [byte[]]$Body,
        [hashtable]$ExtraHeaders = @{}
    )

    $header = "HTTP/1.1 $StatusCode $StatusText`r`n"
    $header += "Content-Type: $ContentType`r`n"
    $header += "Content-Length: $($Body.Length)`r`n"
    $header += "Connection: close`r`n"
    $header += "Access-Control-Allow-Origin: *`r`n"
    $header += "X-SideloadHub: $serverVersion`r`n"
    foreach ($key in $ExtraHeaders.Keys) {
        $header += "$key`: $($ExtraHeaders[$key])`r`n"
    }
    $header += "`r`n"

    $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
    $Stream.Write($headerBytes, 0, $headerBytes.Length)
    if ($Body.Length -gt 0) {
        $Stream.Write($Body, 0, $Body.Length)
    }
}

function Get-JsonBody {
    param([object]$Data)
    $json = $Data | ConvertTo-Json -Depth 6 -Compress
    [System.Text.Encoding]::UTF8.GetBytes($json)
}

function Build-DashboardHtml {
    param(
        [string]$BaseUrl,
        [array]$Apps
    )

    $cards = ""
    foreach ($app in $Apps) {
        $sizeMB = [math]::Round($app.sizeBytes / 1MB, 1)
        $cards += @"
    <a class="card" href="$($app.webPath)">
      <div class="icon" style="background:$($app.accent)22;color:$($app.accent)">⬇</div>
      <div>
        <h2>$($app.name)</h2>
        <p>v$($app.version) · $($sizeMB) MB</p>
      </div>
    </a>
"@
    }

    if (-not $cards) {
        $cards = "<p class='empty'>Aucune app disponible. Lance Sync-GitHubApps.ps1 ou place des IPA dans build-output.</p>"
    }

    return @"
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>SideloadHub</title>
  <style>
    body { font-family: -apple-system, Segoe UI, sans-serif; background: #070b14; color: #fff; margin: 0; padding: 24px; }
    .hero { max-width: 720px; margin: 0 auto 24px; }
    h1 { margin: 0 0 8px; font-size: 2rem; }
    .sub { color: rgba(255,255,255,.55); margin-bottom: 24px; }
    .grid { display: grid; gap: 12px; max-width: 720px; margin: 0 auto; }
    .card { display: flex; gap: 16px; align-items: center; background: rgba(255,255,255,.06); border: 1px solid rgba(255,255,255,.12);
      border-radius: 16px; padding: 16px; text-decoration: none; color: inherit; }
    .icon { width: 48px; height: 48px; border-radius: 12px; display: grid; place-items: center; font-size: 1.4rem; }
    .card h2 { margin: 0 0 4px; font-size: 1.1rem; }
    .card p { margin: 0; color: rgba(255,255,255,.55); font-size: .9rem; }
    .empty { color: rgba(255,255,255,.5); }
    code { background: rgba(255,255,255,.08); padding: 2px 6px; border-radius: 6px; }
  </style>
</head>
<body>
  <div class="hero">
    <h1>SideloadHub</h1>
    <p class="sub">Hub local pour mettre à jour tes apps sideloadées.<br>API: <code>$BaseUrl/api/v1/catalog</code></p>
  </div>
  <div class="grid">$cards</div>
</body>
</html>
"@
}

function Build-AppPageHtml {
    param(
        [object]$App,
        [string]$DownloadUrl
    )

    $sizeMB = [math]::Round($App.sizeBytes / 1MB, 1)
    return @"
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$($App.name)</title>
  <style>
    body { font-family: -apple-system, sans-serif; background: #070b14; color: #fff; min-height: 100vh; display: grid; place-items: center; margin: 0; }
    .card { background: rgba(255,255,255,.08); border: 1px solid rgba(255,255,255,.15); border-radius: 20px; padding: 32px; text-align: center; max-width: 420px; }
    .btn { display: inline-block; margin-top: 20px; background: $($App.accent); color: #001; text-decoration: none; padding: 14px 28px; border-radius: 12px; font-weight: 700; }
    p { color: rgba(255,255,255,.6); }
  </style>
</head>
<body>
  <div class="card">
    <h1>$($App.name)</h1>
    <p>Version $($App.version) · $($sizeMB) MB</p>
    <a class="btn" href="$DownloadUrl">Telecharger l IPA</a>
    <p style="margin-top:16px;font-size:.85rem">Ouvre ensuite avec AltStore ou transfère vers Sideloadly.</p>
  </div>
</body>
</html>
"@
}

function Handle-Client {
    param(
        [System.Net.Sockets.TcpClient]$Client,
        [object]$Config,
        [string]$BaseUrl
    )

    try {
        $stream = $Client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII, $false, 4096, $true)
        $requestLine = $reader.ReadLine()
        if (-not $requestLine) { return }

        while ($true) {
            $line = $reader.ReadLine()
            if ([string]::IsNullOrEmpty($line)) { break }
        }

        $path = "/"
        if ($requestLine -match '^GET\s+([^\s?]+)') { $path = $Matches[1] }

        $catalog = Get-AppCatalog -Config $Config
        $clientIP = $Client.Client.RemoteEndPoint.Address.ToString()
        $time = Get-Date -Format "HH:mm:ss"

        if ($path -eq "/api/v1/health") {
            $body = Get-JsonBody @{
                service = "SideloadHub"
                version = $serverVersion
                apps = $catalog.Count
            }
            Send-HttpResponse -Stream $stream -StatusCode 200 -StatusText "OK" -ContentType "application/json; charset=utf-8" -Body $body
            return
        }

        if ($path -eq "/api/v1/catalog") {
            $body = Get-CatalogJsonBody -Catalog $catalog -BaseUrl $BaseUrl
            Send-HttpResponse -Stream $stream -StatusCode 200 -StatusText "OK" -ContentType "application/json; charset=utf-8" -Body $body
            return
        }

        if ($path -match '^/api/v1/apps/([^/]+)/download$') {
            $appId = $Matches[1]
            $appConfig = $Config.apps | Where-Object { $_.id -eq $appId } | Select-Object -First 1
            if (-not $appConfig) {
                $body = [System.Text.Encoding]::UTF8.GetBytes('{"error":"not found"}')
                Send-HttpResponse -Stream $stream -StatusCode 404 -StatusText "Not Found" -ContentType "application/json" -Body $body
                return
            }

            $ipaPath = Join-Path (Join-Path $OutputRoot $appId) $appConfig.github.ipaFileName
            if (-not (Test-Path $ipaPath)) {
                $body = [System.Text.Encoding]::UTF8.GetBytes('{"error":"ipa missing"}')
                Send-HttpResponse -Stream $stream -StatusCode 404 -StatusText "Not Found" -ContentType "application/json" -Body $body
                return
            }

            $bytes = [System.IO.File]::ReadAllBytes($ipaPath)
            Send-HttpResponse -Stream $stream -StatusCode 200 -StatusText "OK" -ContentType "application/octet-stream" -Body $bytes -ExtraHeaders @{
                "Content-Disposition" = "attachment; filename=$($appConfig.github.ipaFileName)"
            }
            Write-Host "  [$time] DL $($appConfig.name) <- $clientIP" -ForegroundColor Green
            return
        }

        if ($path -match '^/apps/([^/]+)$') {
            $appId = $Matches[1]
            $app = $catalog | Where-Object { $_.id -eq $appId } | Select-Object -First 1
            if (-not $app) {
                $body = [System.Text.Encoding]::UTF8.GetBytes("App introuvable")
                Send-HttpResponse -Stream $stream -StatusCode 404 -StatusText "Not Found" -ContentType "text/plain" -Body $body
                return
            }
            $html = Build-AppPageHtml -App $app -DownloadUrl "$BaseUrl$($app.downloadPath)"
            $body = [System.Text.Encoding]::UTF8.GetBytes($html)
            Send-HttpResponse -Stream $stream -StatusCode 200 -StatusText "OK" -ContentType "text/html; charset=utf-8" -Body $body
            return
        }

        if ($path -eq "/" -or $path -eq "") {
            $html = Build-DashboardHtml -BaseUrl $BaseUrl -Apps $catalog
            $body = [System.Text.Encoding]::UTF8.GetBytes($html)
            Send-HttpResponse -Stream $stream -StatusCode 200 -StatusText "OK" -ContentType "text/html; charset=utf-8" -Body $body
            return
        }

        $body = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
        Send-HttpResponse -Stream $stream -StatusCode 404 -StatusText "Not Found" -ContentType "text/plain" -Body $body
    }
    catch {
        # client deconnecte
    }
    finally {
        $Client.Close()
    }
}

if (-not $SkipSync) {
    Write-Host "Synchronisation GitHub (si token disponible)..." -ForegroundColor Cyan
    & (Join-Path $scriptDir "Sync-GitHubApps.ps1") -OutputRoot $OutputRoot | Out-Null
}

$config = Read-Config
$catalog = Get-AppCatalog -Config $config
$localIP = Get-LocalIPv4
if (-not $localIP) { $localIP = "127.0.0.1" }
$baseUrl = "http://${localIP}:$Port/"

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
try { $listener.Start() }
catch {
    Write-Host "Port $Port indisponible. Essaie -Port 9080" -ForegroundColor Red
    exit 1
}

Clear-Host
Write-Host ''
Write-Host '  ============================================' -ForegroundColor Magenta
Write-Host '     SideloadHub - Serveur LAN' -ForegroundColor Magenta
Write-Host '  ============================================' -ForegroundColor Magenta
Write-Host ''
Write-Host '  URL iPhone / navigateur:' -ForegroundColor White
Write-Host "  $baseUrl" -ForegroundColor Green
Write-Host ''
Write-Host '  API catalog:' -ForegroundColor White
Write-Host "  ${baseUrl}api/v1/catalog" -ForegroundColor Green
Write-Host ''
Write-Host "  Apps disponibles: $($catalog.Count)" -ForegroundColor Cyan
foreach ($app in $catalog) {
    $sizeMB = [math]::Round($app.sizeBytes / 1MB, 1)
    $line = '    - {0} v{1} ({2} MB)' -f $app.name, $app.version, $sizeMB
    Write-Host $line -ForegroundColor DarkGray
}
Write-Host ''
Write-Host '  Connecte l app SideloadHub sur iPhone avec cette IP.' -ForegroundColor Yellow
Write-Host '  Ctrl+C pour arreter' -ForegroundColor Yellow
Write-Host ''

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        Handle-Client -Client $client -Config $config -BaseUrl $baseUrl
    }
}
finally {
    $listener.Stop()
}
