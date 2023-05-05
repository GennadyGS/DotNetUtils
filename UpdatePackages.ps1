param(
    $packageNamePattern = "*",
    $version,
    $targetPath = ".",
    $packageSource,
    $framework,
    [switch][Alias("pre")]$prerelease,
    [switch]$match
)

if (!$match) {
    $packageNamePattern = $packageNamePattern.Replace(".", "`\.").Replace("*", "[\w\.]*")
    "Package name pattern: '$packageNamePattern'"
}

if ($version) { $versionParam = "-v:$version" }
if ($packageSource) { $sourceParam = "-s:$packageSource" }
if ($framework) { $frameworkParam = "-f:$framework" }
if ($prerelease) { $prereleaseParam = "--prerelease" }

Function UpdatePackages {
    param (
        $fileName
    )

    "Update packages by pattern '$packageNamePattern' in file '$fileName'"
    Select-String -Path $fileName `
        -Pattern "<PackageReference Include=\`"($packageNamePattern)\`"" `
    | ForEach-Object { $_.Matches } `
    | ForEach-Object { $_.Groups[1].Value } `
    | ForEach-Object {
        . dotnet.exe add $fileName package $_ `
            $versionParam $frameworkParam $sourceParam $prereleaseParam
    }
}

dotnet nuget locals http-cache --clear
Get-ChildItem -Path $targetPath -Include "*.csproj", "*.fsproj" -Recurse `
| Where-Object { (Get-Content $_) -match "Sdk=""Microsoft.NET.Sdk" }
| Select-String "<PackageReference Include=`"$packageNamePattern`"" -List `
| ForEach-Object { UpdatePackages $_.Path }
