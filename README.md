# Packer Script Execution Guide

This guide provides instructions on setting up environment variables and running the `Run-Packer.ps1` PowerShell script for Packer operations.

## Setting Environment Variables

Environment variables are used to pass configuration options and settings to the PowerShell script. These variables can be set both locally (for the current PowerShell session) and system-wide.

### Prerequisites

- Administrative privileges are required to set system environment variables.
- PowerShell must be run as an administrator to execute these scripts.

### Populate Environment Variables for local env - Populate-LocalVars.ps1

Run this PowerShell script to set the required environment variables.

You can run this script in a limited configuration, for example:

```powershell
# PowerShell script to set user-level environment variables with predefined values for Linux
# Define a hashtable with key-value pairs for environment variables
$predefinedVariableValues = @{
    "WORKING_DIRECTORY" = "example_working_directory"
    "RUN_PACKER_BUILD" = "true"
    "RUN_PACKER_VALIDATE" = "true"
    "RUN_PACKER_INIT" = "true"
    "ENABLE_DEBUG_MODE" = "true"
    "PACKER_VERSION" = "latest"
    "PKR_VAR_registry_username" = "example"
    "PKR_VAR_registry_password" = "example"
}

# Set each predefined variable
foreach ($varName in $predefinedVariableValues.Keys) {
    $value = $predefinedVariableValues[$varName]

    if ($isLinux) {
        # Ensure the PowerShell profile directory exists
        $profileDirectory = [System.IO.Path]::GetDirectoryName($PROFILE)
        if (-not (Test-Path $profileDirectory)) {
            New-Item -ItemType Directory -Path $profileDirectory -Force
        }

        # Ensure the PowerShell profile file exists
        if (-not (Test-Path $PROFILE)) {
            New-Item -ItemType File -Path $PROFILE -Force
        }

        # Append to PowerShell profile and set in current session
        $exportCommand = "`n`$Env:$varName = `"$value`""
        Add-Content -Path $PROFILE -Value $exportCommand
        Set-Variable -Name $varName -Value $value -Scope Global
    }
    elseif ($IsMacOS)
    {
        # Ensure the PowerShell profile directory exists
        $profileDirectory = [System.IO.Path]::GetDirectoryName($PROFILE)
        if (-not (Test-Path $profileDirectory)) {
            New-Item -ItemType Directory -Path $profileDirectory -Force
        }

        # Ensure the PowerShell profile file exists
        if (-not (Test-Path $PROFILE)) {
            New-Item -ItemType File -Path $PROFILE -Force
        }

        # Append to PowerShell profile and set in current session
        $exportCommand = "`n`$Env:$varName = `"$value`""
        Add-Content -Path $PROFILE -Value $exportCommand
        Set-Variable -Name $varName -Value $value -Scope Global
    }
    else {
        # On other systems, set user environment variable
        [System.Environment]::SetEnvironmentVariable($varName, $value, [System.EnvironmentVariableTarget]::User)
    }
}

Write-Host "User-level environment variables have been set."
Write-Host "Please close your powershell window and reopen to refresh environment" -ForegroundColor Yellow
```
## Running the Script

To run the Run-Packer.ps1 script with the environment variables, use the following command in PowerShell:

```powershell
.\Run-Packer.ps1 `
-WorkingDirectory "foo/bar" `
-RunPackerInit "true" `
-RunPackerValidate "true"`
-RunPackerBuild "true" `
-DebugMode "true" `
-PackerVersion "latest"`
-PackerFileName "packer.pkr.hcl `
```

### Post-Execution

- After running the script, the Packer operations as specified by the parameters will be executed.
- Remember that changes to system environment variables might require a system restart to be recognized by all applications.


