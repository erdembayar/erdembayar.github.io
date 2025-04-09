# Update-Sitemap.ps1
# PowerShell script to automatically update sitemap.xml based on files in the posts directory

param (
    [string]$PostsDirectory,
    [string]$OutputFile,
    [string]$BaseUrl = "https://erdembayar.github.io"
)

# Determine repo root based on script location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path "$scriptPath\..").Path

# Set defaults if not provided
if (-not $PostsDirectory) { $PostsDirectory = Join-Path $repoRoot 'posts' }
if (-not $OutputFile)     { $OutputFile     = Join-Path $repoRoot 'sitemap.xml' }

# Optional: ensure Write-Verbose always works
$VerbosePreference = "Continue"

Write-Verbose "Starting sitemap generation..."
Write-Verbose "Posts directory: $PostsDirectory"
Write-Verbose "Output file: $OutputFile"

# Get all files from the posts directory
$allPostFiles = Get-ChildItem -Path $PostsDirectory -File

# Validate file naming convention and filter for valid posts
$validPostFiles = @()
$invalidPostFiles = @()

foreach ($file in $allPostFiles) {
    # Skip index.json and README.md files
    if ($file.Name -eq "index.json" -or $file.Name -eq "README.md") {
        continue
    }
    
    # Check if file has .md extension
    if ($file.Extension -ne ".md") {
        $invalidPostFiles += $file
        continue
    }
    
    # Check file naming convention (YYYY-MM-DD-title.md)
    if ($file.BaseName -match '^(\d{4})-(\d{2})-(\d{2})-(.+)$') {
        $year = [int]$matches[1]
        $month = [int]$matches[2]
        $day = [int]$matches[3]
        
        # Validate date components
        $validDate = $true
        if ($year -lt 2025) {
            $validDate = $false
            Write-Host "Invalid year (must be >= 2025): $($file.Name)" -ForegroundColor Yellow
        }
        if ($month -lt 1 -or $month -gt 12) {
            $validDate = $false
            Write-Host "Invalid month: $($file.Name)" -ForegroundColor Yellow
        }
        if ($day -lt 1 -or $day -gt 31) {
            $validDate = $false
            Write-Host "Invalid day: $($file.Name)" -ForegroundColor Yellow
        }
        
        if ($validDate) {
            # Add date property for sorting
            $file | Add-Member -NotePropertyName PostDate -NotePropertyValue ([DateTime]::new($year, $month, $day))
            $validPostFiles += $file
        } else {
            $invalidPostFiles += $file
        }
    } else {
        Write-Host "Invalid filename format (should be YYYY-MM-DD-title.md): $($file.Name)" -ForegroundColor Yellow
        $invalidPostFiles += $file
    }
}

# Sort posts by date (newest first)
$postFiles = $validPostFiles | Sort-Object PostDate -Descending

# Report validation results
Write-Host "Found $($postFiles.Count) valid posts" -ForegroundColor Green
if ($invalidPostFiles.Count -gt 0) {
    Write-Host "Found $($invalidPostFiles.Count) invalid files in posts directory" -ForegroundColor Red
    Write-Host "Files must follow YYYY-MM-DD-title.md naming convention with year >= 2025" -ForegroundColor Yellow
}

# Get all pages in the root directory
$rootPages = Get-ChildItem -Path $repoRoot -Filter "*.html" -File

# Create XML sitemap header
$xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
"@

# Add homepage (index.html)
$xml += @"

    <url>
        <loc>$BaseUrl/index.html</loc>
        <lastmod>$(Get-Date -Format "yyyy-MM-dd")</lastmod>
        <priority>1.0</priority>
    </url>
"@

# Add root pages
foreach ($page in $rootPages) {
    # Skip index.html as it's already added
    if ($page.Name -ne "index.html") {
        $lastMod = $page.LastWriteTime.ToString("yyyy-MM-dd")
        
        $xml += @"

    <url>
        <loc>$BaseUrl/$($page.Name)</loc>
        <lastmod>$lastMod</lastmod>
        <priority>0.8</priority>
    </url>
"@
    }
}

# Process each post file
foreach ($file in $postFiles) {
    $lastMod = $file.LastWriteTime.ToString("yyyy-MM-dd")
    $postId = $file.BaseName
    
    # For markdown posts, we use the index.html?post=ID format instead of direct file links
    $xml += @"

    <url>
        <loc>$BaseUrl/index.html?post=$postId</loc>
        <lastmod>$lastMod</lastmod>
        <priority>0.7</priority>
    </url>
"@
}

# Close the XML
$xml += @"

</urlset>
"@

# Write the XML to the output file
$xml | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "Sitemap generated successfully at $OutputFile"
Write-Host "Added $($postFiles.Count) posts and $($rootPages.Count - 1) root pages to the sitemap"