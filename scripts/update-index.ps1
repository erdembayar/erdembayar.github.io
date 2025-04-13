# Update-Index.ps1
# PowerShell script to automatically update blog/index.json based on markdown files in the blog directory

param (
    [string]$BlogDirectory,
    [string]$OutputFile
)

# Determine repo root based on script location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path "$scriptPath\..").Path

# Set defaults if not provided
if (-not $BlogDirectory) { $BlogDirectory = Join-Path $repoRoot 'blog' }
if (-not $OutputFile)     { $OutputFile     = Join-Path $BlogDirectory 'index.json' }

# Optional: ensure Write-Verbose always works
$VerbosePreference = "Continue"

Write-Verbose "Starting index.json generation..."
Write-Verbose "Blog directory: $BlogDirectory"
Write-Verbose "Output file: $OutputFile"

# Delete existing index.json file if it exists
if (Test-Path $OutputFile) {
    Write-Verbose "Removing existing index.json file..."
    Remove-Item -Path $OutputFile -Force
}

# Get all files from the blog directory
$allPostFiles = Get-ChildItem -Path $BlogDirectory -Filter "*.md" -File

Write-Host "All post files: $($allPostFiles.Count)" 

# Validate file naming convention and filter for valid posts
$validPosts = @()
$invalidFiles = @()

foreach ($file in $allPostFiles) {
    # Skip README.md files
    if ($file.Name -eq "README.md") {
        Write-Verbose "Skipping README.md file"
        continue
    }
    
    # Check file naming convention (YYYY-MM-DD-title.md)
    Write-Host "Processing file: $($file.Name)"
    if ($file.BaseName -match '^(\d{4})-(\d{2})-(\d{2})-(.+)$') {
        $year = [int]$matches[1]
        $month = [int]$matches[2]
        $day = [int]$matches[3]
        $title = $matches[4] -replace '-', ' '
        Write-Host "Processing file: $($file.Name) $year-$month-$day $title"
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
        
        Write-Host "Valid date: $validDate"

        if ($validDate) {
            # Try to extract title from first line of markdown if it starts with # (h1 heading)
            $content = Get-Content -Path $file.FullName -TotalCount 1
            if ($content -match '^# (.+)') {
                $extractedTitle = $matches[1]
                Write-Host "Using H1 title from markdown: $extractedTitle" -ForegroundColor Green
            } else {
                # Use filename-based title as fallback
                $extractedTitle = $title
                Write-Host "Using filename-based title: $extractedTitle" -ForegroundColor Yellow
            }
            
            # Create post object
            $post = @{
                title = $extractedTitle
                date = "$year-$($month.ToString('00'))-$($day.ToString('00'))"
                id = $file.BaseName
            }
            
            $validPosts += $post
        } else {
            $invalidFiles += $file
        }
    } else {
        Write-Host "Invalid filename format (should be YYYY-MM-DD-title.md): $($file.Name)" -ForegroundColor Yellow
        $invalidFiles += $file
    }
}

# Sort posts by date (newest first)
$sortedPosts = $validPosts | Sort-Object { [DateTime]::Parse($_.date) } -Descending

# Report validation results
Write-Host "Found $($validPosts.Count) valid posts" -ForegroundColor Green
if ($invalidFiles.Count -gt 0) {
    Write-Host "Found $($invalidFiles.Count) invalid files in blog directory" -ForegroundColor Red
    Write-Host "Files must follow YYYY-MM-DD-title.md naming convention with year >= 2025" -ForegroundColor Yellow
}

# Convert to JSON - Always make sure it's an array even with a single post
# Ensure array format by wrapping single object in an array before conversion
if ($sortedPosts.Count -eq 1) {
    # Force array with single item by using @() array constructor
    $postsArray = @($sortedPosts)
    $json = $postsArray | ConvertTo-Json -Depth 3
} else {
    # Regular conversion (will be array if multiple items)
    $json = $sortedPosts | ConvertTo-Json -Depth 3
}

# Write the JSON to the output file
$json | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "index.json generated successfully at $OutputFile"
Write-Host "Added $($validPosts.Count) posts to index.json" 