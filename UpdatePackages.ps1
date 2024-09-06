param(
    $packageNamePattern,
    [Alias("e")] $excludedPackageNamePattern,
    [Alias("v")] $version,
    $targetPath = ".",
    $packageSource,
    [Alias("f")] $framework,
    [Alias("c")] $configuration = "Debug",
    [switch] $build,
    [switch] $test,
    [switch] [Alias("pre")] $prerelease,
    [switch] $match
)
Function ConvertPatternToRegex($pattern) {
    ($pattern ?? "").Replace(".", "`\.").Replace("*", "[\w\.]*")
}

Function UpdatePackages($fileName) {
    $excludedPattern = "^$excludedPackageNamePattern$"
    Write-Host "Updating packages by pattern '$packageNamePattern' in project '$fileName' ..." `
        -ForegroundColor $commandColor
    Select-String -Path $fileName -Pattern "<PackageReference Include=\`"($packageNamePattern)\`"" `
    | ForEach-Object { $_.Matches } `
    | ForEach-Object { $_.Groups[1].Value } `
    | Where-Object { !($_ -match $excludedPattern) }
    | ForEach-Object {
        $script:updated = $true
        RunAndLogCommand dotnet add $fileName package $_ `
            $versionParam $frameworkParam $sourceParam $prereleaseParam
    }
}

. $PSScriptRoot\Common.ps1

$packageNamePattern = $packageNamePattern ?? ($match ? "[\w\.]*" : "*")
if (!$match) {
    $packageNamePattern = ConvertPatternToRegex($packageNamePattern)
    $excludedPackageNamePattern = ConvertPatternToRegex($excludedPackageNamePattern)
}

if ($version) { $versionParam = "-v:$version" }
if ($packageSource) { $sourceParam = "-s:$packageSource" }
if ($framework) { $frameworkParam = "-f:$framework" }
if ($prerelease) { $prereleaseParam = "--prerelease" }
$updated = $false

Push-Location $targetPath

& dotnet nuget locals http-cache --clear
if (!(Test-Path $targetPath -PathType Container)) {
    throw "Target directory is not found by path $targetPath."
}
Get-ChildItem -Path $targetPath -Include "*.csproj", "*.fsproj" -Recurse `
| Where-Object { (Get-Content $_) -match "Sdk=""Microsoft.NET.Sdk" }
| Select-String "<PackageReference Include=`"$packageNamePattern`"" -List `
| ForEach-Object { UpdatePackages $_.Path }

if (!$updated) { return }

if ($test) { RunAndLogCommand dotnet test '-m:1' -c $configuration }
elseif ($build) { RunAndLogCommand dotnet build -c $configuration }

Pop-Location