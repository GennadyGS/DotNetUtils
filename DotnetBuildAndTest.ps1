param (
    [string] $TestFilter,
    [string] $Configuration = "Debug",
    [switch] $Rebuild,
    [switch] $NoTest
)

. $PsScriptRoot/Common.ps1

$RebuildParameter = $Rebuild ? '--no-incremental' : ''
$buildCommand = "dotnet build $RebuildParameter --configuration $Configuration"
RunExpressionAndLog `
    $buildCommand `
    {
        Invoke-Expression $buildCommand
        if ($global:LastExitCode -ne 0) {
            Write-Error "'$buildCommand' is failed with code $global:LastExitCode"
            exit 125  # tells git bisect to skip this commit
        }
    }

if (-not $NoTest) {
    $filterParameter = $TestFilter ? "--filter $TestFilter" : ""
    RunCommandWithLog dotnet test --no-build $filterParameter --configuration $Configuration
}
