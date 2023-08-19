param(
    [Parameter(Mandatory=$true)] $packageName,
    $version,
    $targetPath = ".",
    $packageSource,
    [Alias("f")] $framework,
    [switch] $build,
    [switch] $test,
    [switch] [Alias("pre")] $prerelease
)

. $PSScriptRoot\Common.ps1

if ($version) { $versionParam = "-v:$version" }
if ($packageSource) { $sourceParam = "-s:$packageSource" }
if ($framework) { $frameworkParam = "-f:$framework" }
if ($prerelease) { $prereleaseParam = "--prerelease" }

Function AddPackage {
    param (
        $fileName
    )

    Write-Host "Adding package '$packageName' to project '$fileName' ..." `
        -ForegroundColor $commandColor
    RunAndLogCommand `
        dotnet.exe add $fileName package $packageName `
            $versionParam $frameworkParam $sourceParam $prereleaseParam
}

& dotnet nuget locals http-cache --clear
Get-ChildItem -Path $targetPath -Include "*.csproj", "*.fsproj" -Recurse `
| Where-Object { (Get-Content $_) -match "Sdk=""Microsoft.NET.Sdk" }
| ForEach-Object { AddPackage $_ }

if ($test) { RunAndLogCommand dotnet test $targetPath }
elseif ($build) { RunAndLogCommand dotnet build $targetPath }
