param (
    [string]$DockerFileName = "Dockerfile",
    [string]$DockerImageName = "example",
    [string]$DockerContainerName = "ubuntu",
    [string]$WorkingDirectory = (Get-Location).Path,
    [string]$DebugMode = "false"
)

# Function to check if the Dockerfile exists
function Check-DockerFileExists {
    $filePath = Join-Path -Path $WorkingDirectory -ChildPath $DockerFileName
    if (-not (Test-Path -Path $filePath)) {
        Write-Error "Error: Dockerfile not found at $filePath. Exiting."
        exit 1
    }
    else {
        Write-Host "Success: Dockerfile found at: $filePath" -ForegroundColor Green
    }
}

# Function to check if Docker is installed
function Check-DockerExists {
    try {
        $dockerPath = Get-Command docker -ErrorAction Stop
        Write-Host "Success: Docker found at: $($dockerPath.Source)" -ForegroundColor Green
    }
    catch {
        Write-Error "Error: Docker is not installed or not in PATH. Exiting."
        exit 1
    }
}

# Function to build a Docker image
function Build-DockerImage {
    try {
        Write-Host "Info: Building Docker image $DockerImageName from $DockerFileName" -ForegroundColor Green
        docker build -t $DockerImageName -f $DockerFileName | Out-Host
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        else {
            Write-Error "Error: Docker build failed with exit code $LASTEXITCODE"
            return $false
        }
    }
    catch {
        Write-Error "Error: Docker build encountered an exception"
        return $false
    }
}

# Convert string parameters to boolean
$DebugMode = $DebugMode -eq "true"

# Enable debug mode if DebugMode is set to $true
if ($DebugMode) {
    $DebugPreference = "Continue"
}

# Diagnostic output
Write-Debug "DockerFileName: $DockerFileName"
Write-Debug "DockerImageName: $DockerImageName"
Write-Debug "DockerContainerName: $DockerContainerName"
Write-Debug "DebugMode: $DebugMode"

# Checking prerequisites
Check-DockerExists
Check-DockerFileExists

# Execution flow
$buildSuccess = Build-DockerImage | Out-Host

if ($buildSuccess -eq $true) {
    Write-Host "Docker build complete." -ForegroundColor Green
}
else {
    Write-Host "Docker build failed." -ForegroundColor Green
    exit 1
}
