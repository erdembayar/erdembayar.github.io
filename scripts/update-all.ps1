# Update-All.ps1
# Master script to update both the index.json and sitemap.xml files

param (
    [string]$BlogDirectory,
    [string]$SitemapFile,
    [string]$IndexFile,
    [string]$BaseUrl = "https://erdembayar.github.io"
)

# Determine repo root based on script location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path "$scriptPath\..").Path

# Set defaults if not provided
if (-not $BlogDirectory) { $BlogDirectory = Join-Path $repoRoot 'blog' }
if (-not $SitemapFile)    { $SitemapFile    = Join-Path $repoRoot 'sitemap.xml' }
if (-not $IndexFile)      { $IndexFile      = Join-Path $BlogDirectory 'index.json' }

Write-Host "========== Updating Blog Files ==========" -ForegroundColor Cyan

# Update the index.json file
Write-Host "`n[1/2] Updating index.json" -ForegroundColor Green
& "$scriptPath\update-index.ps1" -BlogDirectory $BlogDirectory -OutputFile $IndexFile

# Update the sitemap.xml file
Write-Host "`n[2/2] Updating sitemap.xml" -ForegroundColor Green
& "$scriptPath\update-sitemap.ps1" -BlogDirectory $BlogDirectory -OutputFile $SitemapFile -BaseUrl $BaseUrl

Write-Host "`n========== Updates Completed ==========" -ForegroundColor Cyan
Write-Host "index.json: $IndexFile"
Write-Host "sitemap.xml: $SitemapFile" 