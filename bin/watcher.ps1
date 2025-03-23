param (
    [string]$Path = "./",        # Path to a file or directory
    [string]$Filter = "*.ahk?",  # File filter to watch
    [string]$PassArgs = "",      # Arguments to pass to file
    [string]$Action = ""         # Action to be performed after file change
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$esc = [char]27
$err = "[$esc[1;91mERROR$esc[0m]"
$inf = "[$esc[1;94mINFO$esc[0m]"

# Check if the path exists
if (-Not (Test-Path $Path)) { 
    Write-Host "$err - Path '$Path' does not exist"
    exit 1
}

# Determine whether watching a file or directory
if (Test-Path $Path -PathType Container) {
    $FilePath = $Path
    $FileName = $Filter
    Write-Host "$inf - Watching for changes in '$Path$Filter'"
} else {
    $FilePath = Split-Path -Path $Path -Parent
    $FileName = Split-Path -Path $Path -Leaf
    Write-Host "$inf - Watching for changes in '$Path'"
}

# Create FileSystemWatcher
$Watcher = New-Object IO.FileSystemWatcher $FilePath, $FileName -Property @{ 
    IncludeSubdirectories = $false
    EnableRaisingEvents = $true
}

# Define the temporary directory for execution
if (-Not (Test-Path $env:ahk_temp)) { New-Item -ItemType Directory -Path $env:ahk_temp | Out-Null }

# Store running processes
$RunningProcesses = @()

if ($PassArgs) {
    $PassArgs = "-ArgumentList $Args"
}

# Function to execute AHK file
function Reload-ahk {
    param ([string]$FilePath)

    try {
        $fileName = [System.IO.Path]::GetFileName($FilePath)
        $tempFile = Join-Path -Path $env:ahk_temp -ChildPath $fileName
        Copy-Item -Path $FilePath -Destination $tempFile -Force
        $proc = Start-Process "$env:bin_launcher\Launcher-$env:sys_arch.exe" $PassArgs -PassThru
        $RunningProcesses += $proc
        if ($Action) { Invoke-Expression $Action }
    } catch {
        Write-Host "$err - Running file: $_"
    }
}

# Function to handle cleanup on exit
function Clean-ahk {
    Write-Host "`n$inf - Stopping running scripts..."
    foreach ($proc in $RunningProcesses) {
        if (!$proc.HasExited) {
            Stop-Process -Id $proc.Id -Force
            Write-Host "$inf - Stopped process: $($proc.Name)"
        }
    }

    Unregister-Event -SubscriptionId $onChange.Id
    $Watcher.Dispose()
    Write-Host "$inf - File Watcher stopped`n"
    exit 0
}

# Define event action for file changes
$scriptBlock = {
    param ($sender, $event)
    Write-Host "$inf - File '$($event.FullPath)' was Changed"
    Reload-ahk $event.FullPath
}

# Run matching files before starting the watcher
Get-ChildItem -Path $FilePath -Filter $FileName | ForEach-Object {
    Write-Host "$inf - Running existing file: $($_.FullName)"
    Reload-ahk $_.FullName
}

# Register the event
$onChange = Register-ObjectEvent $Watcher "Changed" -Action $scriptBlock 

# Keep script running indefinitely
Write-Host "$inf - Press Escape to stop Watching..."
try {
    while ($true) {
        if ([console]::KeyAvailable) {
            $Key = [console]::ReadKey($true)
            if ($Key.Key -eq "Escape") { throw "Exit" }
        }
        Start-Sleep -Milliseconds 500  # Prevents CPU overuse
    }
} finally { Clean-ahk }

exit 0
