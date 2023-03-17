param(
    $packageNamePattern = "*",
    $version,
    $framework,
    $source,
    [switch]$match,
    [switch]$prerelease
)

if (!$match) {
    $packageNamePattern = $packageNamePattern.Replace(".", "`\.").Replace("*", "[\w\.]*")
    "Package name pattern: '$packageNamePattern'"
}
if ($version) { $versionParam = "-v:$version" }
if ($framework) { $frameworkParam = "-f:$framework" }
if ($source) { $sourceParam = "-s:$source" }
if ($prerelease) { $prereleaseParam = "--prerelease" }

Function UpdatePackages {
    param (
        $fileName
    )
    "Update packages by pattern '$packageNamePattern' in file '$fileName'"
    $directoryPath = Split-Path -Path $fileName -Parent
    Push-Location $directoryPath
    Select-String -Path $fileName `
        -Pattern "<PackageReference Include=\`"($packageNamePattern)\`"" `
    | ForEach-Object { $_.Matches } `
    | ForEach-Object { $_.Groups[1].Value } `
    | ForEach-Object {
         . dotnet.exe add package $_ $versionParam $frameworkParam $sourceParam $prereleaseParam
    }
    Pop-Location
}

dotnet nuget locals http-cache --clear
Get-ChildItem -Include "*.csproj", "*.fsproj" -Recurse `
| Select-String "<PackageReference Include=`"$packageNamePattern`"" -List `
| ForEach-Object { UpdatePackages $_.Path }
