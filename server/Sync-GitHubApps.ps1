#Requires -Version 5.1
param(
    [string]$ConfigPath = "",
    [string]$OutputRoot = "",
    [string]$Token = $env:GITHUB_TOKEN
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

if (-not $ConfigPath) { $ConfigPath = Join-Path $scriptDir "config\apps.json" }
if (-not $OutputRoot) { $OutputRoot = Join-Path $repoRoot "build-output" }

if (-not (Test-Path $ConfigPath)) { throw "Config introuvable: $ConfigPath" }

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

function Get-IpaMetadata {
    param([string]$IpaPath)

    $result = @{
        version = "?"
        build = "?"
    }

    if (-not (Test-Path $IpaPath)) { return $result }

    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("sideloadhub-" + [guid]::NewGuid().ToString("N"))
    try {
        Expand-Archive -Path $IpaPath -DestinationPath $tempDir -Force
        $infoPlist = Get-ChildItem -Path $tempDir -Filter "Info.plist" -Recurse | Select-Object -First 1
        if (-not $infoPlist) { return $result }

        $plist = & plutil -convert xml1 -o - $infoPlist.FullName 2>$null
        if (-not $plist) { return $result }

        if ($plist -match '<key>CFBundleShortVersionString</key>\s*<string>([^<]+)</string>') {
            $result.version = $Matches[1]
        }
        if ($plist -match '<key>CFBundleVersion</key>\s*<string>([^<]+)</string>') {
            $result.build = $Matches[1]
        }
    }
    catch {
        # plutil absent sur Windows : fallback taille/date
    }
    finally {
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
    }

    return $result
}

function Download-LatestIpa {
    param(
        [object]$App,
        [string]$Token
    )

    $gh = $App.github
    if (-not $gh) { return $null }

    $headers = @{
        Authorization = "Bearer $Token"
        Accept        = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    $runsUrl = "https://api.github.com/repos/$($gh.owner)/$($gh.repo)/actions/runs?status=success&per_page=5"
    $runs = Invoke-RestMethod -Uri $runsUrl -Headers $headers -Method Get
    $buildRun = $runs.workflow_runs | Where-Object { $_.name -like "*IPA*" -or $_.name -like "*Sideload*" } | Select-Object -First 1
    if (-not $buildRun) { $buildRun = $runs.workflow_runs | Select-Object -First 1 }
    if (-not $buildRun) { throw "Aucun build pour $($gh.repo)" }

    $artifactsUrl = "https://api.github.com/repos/$($gh.owner)/$($gh.repo)/actions/runs/$($buildRun.id)/artifacts"
    $artifacts = Invoke-RestMethod -Uri $artifactsUrl -Headers $headers -Method Get
    $artifact = $artifacts.artifacts | Where-Object { $_.name -eq $gh.artifact } | Select-Object -First 1
    if (-not $artifact) { $artifact = $artifacts.artifacts | Select-Object -First 1 }
    if (-not $artifact) { throw "Artifact introuvable pour $($gh.repo)" }

    $appDir = Join-Path $OutputRoot $App.id
    New-Item -ItemType Directory -Force -Path $appDir | Out-Null

    $zipPath = Join-Path $appDir "artifact.zip"
    $ipaPath = Join-Path $appDir $gh.ipaFileName

    Write-Host "  [$($App.name)] Build #$($buildRun.run_number)..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $artifact.archive_download_url -Headers $headers -OutFile $zipPath

    $extractDir = Join-Path $appDir "extract"
    if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
    Remove-Item $zipPath -Force

    $found = Get-ChildItem -Path $extractDir -Filter "*.ipa" -Recurse | Select-Object -First 1
    if (-not $found) { throw "IPA introuvable pour $($App.name)" }

    Copy-Item $found.FullName $ipaPath -Force
    Remove-Item $extractDir -Recurse -Force

    $meta = @{
        syncedAt = (Get-Date).ToUniversalTime().ToString("o")
        buildNumber = $buildRun.run_number
        commit = $buildRun.head_sha.Substring(0, 7)
        message = $buildRun.head_commit.message
    }
    $meta | ConvertTo-Json | Set-Content (Join-Path $appDir "meta.json") -Encoding UTF8

    return $ipaPath
}

$synced = @()

foreach ($app in $config.apps) {
    $appDir = Join-Path $OutputRoot $app.id
    $ipaPath = Join-Path $appDir $app.github.ipaFileName

    if ($Token) {
        try {
            $ipaPath = Download-LatestIpa -App $app -Token $Token
            Write-Host "  OK $($app.name)" -ForegroundColor Green
        }
        catch {
            Write-Host "  ERREUR $($app.name): $_" -ForegroundColor Red
            if (-not (Test-Path $ipaPath)) { continue }
            Write-Host '  -> IPA local conserve' -ForegroundColor Yellow
        }
    }
    elseif (-not (Test-Path $ipaPath)) {
        Write-Host ('  SKIP {0} - pas de token et pas d IPA local' -f $app.name) -ForegroundColor Yellow
        continue
    }

    if (Test-Path $ipaPath) {
        $synced += $app.id
    }
}

Write-Host ""
Write-Host "$($synced.Count) app(s) disponible(s) dans $OutputRoot" -ForegroundColor Green
return $synced
