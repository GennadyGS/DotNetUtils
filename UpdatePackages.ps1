param(
    $packageNamePattern = "*",
    $version,
    $targetPath = ".",
    $packageSource,
    $framework,
    [switch] $build,
    [switch] $test,
    [switch] [Alias("pre")] $prerelease,
    [switch] $match
)

. $PSScriptRoot\Common.ps1

if (!$match) {
    $packageNamePattern = $packageNamePattern.Replace(".", "`\.").Replace("*", "[\w\.]*")
}

if ($version) { $versionParam = "-v:$version" }
if ($packageSource) { $sourceParam = "-s:$packageSource" }
if ($framework) { $frameworkParam = "-f:$framework" }
if ($prerelease) { $prereleaseParam = "--prerelease" }
$updated = $false

Function UpdatePackages {
    param (
        $fileName
    )

    Write-Host "Updating packages by pattern '$packageNamePattern' in file '$fileName' ..." `
        -ForegroundColor $commandColor
    Select-String -Path $fileName -Pattern "<PackageReference Include=\`"($packageNamePattern)\`"" `
    | ForEach-Object { $_.Matches } `
    | ForEach-Object { $_.Groups[1].Value } `
    | ForEach-Object {
        $script:updated = $true
        RunAndLogCommand dotnet.exe add $fileName package $_ `
            $versionParam $frameworkParam $sourceParam $prereleaseParam
    }
}

RunAndLogCommand dotnet nuget locals http-cache --clear
Get-ChildItem -Path $targetPath -Include "*.csproj", "*.fsproj" -Recurse `
| Where-Object { (Get-Content $_) -match "Sdk=""Microsoft.NET.Sdk" }
| Select-String "<PackageReference Include=`"$packageNamePattern`"" -List `
| ForEach-Object { UpdatePackages $_.Path }

if (!$updated) { return }

if ($test) { RunAndLogCommand dotnet test $targetPath }
elseif ($build) { RunAndLogCommand dotnet build $targetPath }
