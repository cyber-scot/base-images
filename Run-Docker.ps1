<#
.SYNOPSIS
    This script automates Docker operations including building and optionally pushing a Docker image to a specified registry.

.DESCRIPTION
    'Run-Docker.ps1' is a PowerShell script designed for automating Docker tasks. It includes functionalities for building a Docker image from a specified Dockerfile and optionally pushing this image to a Docker registry. The script is flexible and allows users to specify various parameters such as the Dockerfile name, image name, container name, registry details, and working directory.

.PARAMETERS
    DockerFileName
        The name of the Dockerfile to be used for building the Docker image. Default is 'Dockerfile'.

    DockerImageName
        The name to be assigned to the built Docker image. Default is 'example'.

    RegistryUrl
        The URL of the Docker registry where the image should be pushed. Default is 'ghcr.io'.

    RegistryUsername
        The username for the Docker registry.

    RegistryPassword
        The password for the Docker registry.

    WorkingDirectory
        The directory where the Dockerfile is located and where Docker commands will be executed.

    DebugMode
        Enables or disables debug mode. Accepts 'true' or 'false'. Default is 'false'.

    PushDockerImage
        Specifies whether to push the Docker image to the registry. Accepts 'true' or 'false'. Default is 'true'.

.FUNCTIONS
    Convert-ToBoolean
        Converts string parameters to boolean values.

    Check-DockerExists
        Checks if Docker is installed and available in the system's PATH.

    Build-DockerImage
        Builds a Docker image using the specified Dockerfile and path.

    Push-DockerImage
        Pushes the built Docker image to the specified registry.

.EXAMPLE
    ./Run-Docker.ps1 -WorkingDirectory "$(Get-Location)/containers/ubuntu" -RegistryUsername $Env:registry_username -RegistryPassword $Env:registry_password

    This example demonstrates how to run the script with a specified working directory and Docker registry credentials sourced from environment variables.

.NOTES
    Ensure Docker is installed and that the provided credentials for the Docker registry are valid. The script parameters can be adjusted according to specific requirements.

    Author: Craig Thacker
    Date: 11/12/2023
#>

param (
    [string]$DockerFileName = "Dockerfile",
    [string]$DockerImageName = "ubuntu-cicd-base:latest",
    [string]$RegistryUrl = "ghcr.io",
    [string]$RegistryUsername = "myusername",
    [string]$RegistryPassword = "mypassword",
    [string]$WorkingDirectory = (Get-Location).Path,
    [string]$DebugMode = "false",
    [string]$PushDockerImage = "true"
)

# Function to convert string to boolean
function Convert-ToBoolean($value) {
    $valueLower = $value.ToLower()
    if ($valueLower -eq "true") {
        return $true
    }
    elseif ($valueLower -eq "false") {
        return $false
    }
    else {
        Write-Error "Error: Invalid value - $value. Exiting."
        exit 1
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

$DockerImageName = "${RegistryUrl}/${RegistryUsername}/${DockerImageName}"

function Build-DockerImage {
    param (
        [string]$Path,
        [string]$DockerFile
    )

    $filePath = Join-Path -Path $Path -ChildPath $DockerFile

    # Check if Dockerfile exists at the specified path
    if (-not (Test-Path -Path $filePath)) {
        Write-Error "Error: Dockerfile not found at $filePath. Exiting."
        return $false
    }

    try {
        Write-Host "Info: Building Docker image $DockerImageName from $filePath" -ForegroundColor Green
        docker build -t $DockerImageName -f $filePath $Path
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

function Push-DockerImage {
    try {
        Write-Host "Info: Logging into Docker registry $RegistryUrl" -ForegroundColor Green
        $RegistryPassword | docker login $RegistryUrl -u $RegistryUsername --password-stdin

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Info: Pushing Docker image $DockerImageName to $Registry" -ForegroundColor Green
            docker push $DockerImageName | Out-Host
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Success: Docker image pushed successfully." -ForegroundColor Green
                return $true
            }
            else {
                Write-Error "Error: Docker push failed with exit code $LASTEXITCODE"
                return $false
            }
        }
        else {
            Write-Error "Error: Docker login failed with exit code $LASTEXITCODE"
            return $false
        }
    }
    catch {
        Write-Error "Error: An exception occurred during Docker push"
        return $false
    }
    finally {
        Write-Host "Info: Logging out of Docker registry $Registry" -ForegroundColor Green
        docker logout $Registry
    }
}

# Convert string parameters to boolean
$DebugMode = Convert-ToBoolean $DebugMode
$PushDockerImage = Convert-ToBoolean $PushDockerImage

# Enable debug mode if DebugMode is set to $true
if ($DebugMode) {
    $DebugPreference = "Continue"
}

# Diagnostic output
Write-Debug "DockerFileName: $DockerFileName"
Write-Debug "DockerImageName: $DockerImageName"
Write-Debug "DebugMode: $DebugMode"

# Checking prerequisites
Check-DockerExists

# Execution flow
$buildSuccess = Build-DockerImage -Path $WorkingDirectory -DockerFile $DockerFileName

if ($buildSuccess) {
    Write-Host "Docker build complete." -ForegroundColor Green
    if ($PushDockerImage -eq $true) {
        $pushSuccess = Push-DockerImage
        if ($pushSuccess) {
            Write-Host "Docker image push complete." -ForegroundColor Green
        }
        else {
            Write-Host "Docker image push failed." -ForegroundColor Red
            exit 1
        }
    }
}
else {
    Write-Host "Docker build failed." -ForegroundColor Red
    exit 1
}
