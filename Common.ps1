. $PsScriptRoot\ProjectUtils.ps1

$localNugetSourcePath = $Env:NugetPackagesOutputPath
$highlightedColor = "white"

Function RunCommandWithLog {
    if (!$args) {
        throw "Command is not specified"
    }

    $commandText = [string]$args
    RunExpressionAndLog "'$commandText' in '$pwd'" { Invoke-Expression $commandText }
}

Function RunExpressionAndLog(
    [Parameter(Mandatory=$true)] [string] $name,
    [Parameter(Mandatory=$true)] [ScriptBlock] $expression)
{
    WriteHighlighted $name
    $global:LastExitCode = 0
    & $expression
    if ($LastExitCode -ne 0) {
        throw "'$name' failed with code $LastExitCode"
    }
}

Function WriteHighlighted($text) {
    Write-Host $text -ForegroundColor $highlightedColor
}

Function GetDirectoryPath($path) {
    if (Test-Path $path -PathType Leaf) {
        return [IO.Path]::GetDirectoryName($path)
    } else {
        return $path
    }
}
