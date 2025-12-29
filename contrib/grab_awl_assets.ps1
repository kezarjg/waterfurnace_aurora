#!/usr/bin/env pwsh
#
# WaterFurnace Aurora Web Assets Downloader (PowerShell)
# Downloads web interface assets from Aurora Web Aid Tool
#
# Usage:
#   .\grab_awl_assets.ps1 [IP_ADDRESS]
#
# Default IP: 172.20.10.1
#

param(
    [string]$IP = "172.20.10.1"
)

# Color output functions
function Write-Info {
    param([string]$Message)
    Write-Host "INFO: $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "SUCCESS: $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

# Create directory structure
Write-Info "Creating directory structure..."
$directories = @(
    "html",
    "html\css",
    "html\js",
    "html\images"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Success "Created: $dir"
    } else {
        Write-Info "Already exists: $dir"
    }
}

# Define files to download
$files = @(
    @{ Url = "http://$IP/"; OutFile = "html\index.htm" },
    @{ Url = "http://$IP/config.htm"; OutFile = "html\config.htm" },
    @{ Url = "http://$IP/favicon.ico"; OutFile = "html\favicon.ico" },
    @{ Url = "http://$IP/css/index.css"; OutFile = "html\css\index.css" },
    @{ Url = "http://$IP/css/phone.css"; OutFile = "html\css\phone.css" },
    @{ Url = "http://$IP/js/indexc.js"; OutFile = "html\js\indexc.js" },
    @{ Url = "http://$IP/js/configc.js"; OutFile = "html\js\configc.js" },
    @{ Url = "http://$IP/images/aurora.png"; OutFile = "html\images\aurora.png" },
    @{ Url = "http://$IP/images/back.png"; OutFile = "html\images\back.png" },
    @{ Url = "http://$IP/images/cfailed.png"; OutFile = "html\images\cfailed.png" },
    @{ Url = "http://$IP/images/cgood.png"; OutFile = "html\images\cgood.png" },
    @{ Url = "http://$IP/images/cidle.png"; OutFile = "html\images\cidle.png" }
)

# Missing files discovered by check_web_aid_files.sh:
# TODO: Locate and add these files to the download list above
#   - indexat.htm          → html\indexat.htm
#   - js/AjaxSlim.js       → html\js\AjaxSlim.js
#                            (might not be needed - currently commented out in config.htm)

Write-Info "Downloading assets from http://$IP ..."
Write-Host ""

$successCount = 0
$failCount = 0

foreach ($file in $files) {
    try {
        Write-Host "Downloading: $($file.Url) -> $($file.OutFile)" -ForegroundColor Yellow
        Invoke-WebRequest -Uri $file.Url -OutFile $file.OutFile -ErrorAction Stop
        Write-Success "Downloaded: $($file.OutFile)"
        $successCount++
    }
    catch {
        Write-Error-Custom "Failed to download $($file.Url): $($_.Exception.Message)"
        $failCount++
    }
}

Write-Host ""
Write-Info "Download Summary:"
Write-Host "  Total files: $($files.Count)" -ForegroundColor White
Write-Host "  Successful: $successCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor Red

if ($failCount -eq 0) {
    Write-Host ""
    Write-Success "All assets downloaded successfully to '.\html\' directory"
} else {
    Write-Host ""
    Write-Error-Custom "Some downloads failed. Check the errors above."
    exit 1
}
