. $PsScriptRoot\ProjectUtils.ps1

$localNugetSourcePath = $Env:NugetPackagesOutputPath
$commandColor = "white"

Function RunAndLogCommand {
    param (
        [switch] $noLog,
        [switch] $ignoreError
    )

    if (!$args) {
        Throw "Command is not specified for function Run"
    }

    $commandText = [string]$args
    if(!$noLog) {
        Write-Host $commandText -ForegroundColor $commandColor
    }
    Invoke-Expression $commandText
    if (!$ignoreError -and $LastExitCode -ne 0) {
        throw "Command '$commandText' has failed with code $LastExitCode."
    }
}
