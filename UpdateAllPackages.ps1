param(
    $packageNamePattern,
    $version,
    $framework,
    $source
)

if ($version) { $versionParam = "-v $version" }
if ($framework) { $frameworkParam = "-f $framework" }
if ($source) { $sourceParam = "-s $source" }
Function UpdatePackages {
    param (
        $fileName
    )
    "Update packages by pattern '$packageNamePattern' in file '$fileName'"
    $directoryPath = Split-Path -Path $fileName -Parent
    Push-Location $directoryPath
    Select-String -Path $fileName `
        -Pattern "<PackageReference Include=\`"($packageNamePattern)\`" Version" `
    | % { $_.Matches } `
    | % { $_.Groups[1].Value } `
    | % { 
        Invoke-Expression `
            "dotnet.exe add package $_ $versionParam $frameworkParam $sourceParam" }
    Pop-Location
}

dotnet nuget locals http-cache --clear
Get-ChildItem -Include "*.csproj", "*.fsproj" -Recurse `
| Select-String "<PackageReference Include=`"$packageNamePattern`"" -List `
| % { UpdatePackages $_.Path }
