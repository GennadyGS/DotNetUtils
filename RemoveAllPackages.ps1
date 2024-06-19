param(
    $packageNamePattern = "*",
    [switch] $match
)

if (!$match) {
    $packageNamePattern = $packageNamePattern.Replace(".", "`\.").Replace("*", "[\w\.]*")
    "Package name pattern: '$packageNamePattern'"
}

Function RemovePackages {
    param (
        $fileName
    )
    "Remove packages by pattern '$packageNamePattern' in file '$fileName'"
    $directoryPath = Split-Path -Path $fileName -Parent
    Push-Location $directoryPath
    Select-String -Path $fileName `
        -Pattern "<PackageReference Include=\`"($packageNamePattern)\`"" `
    | ForEach-Object { $_.Matches } `
    | ForEach-Object { $_.Groups[1].Value } `
    | ForEach-Object { . dotnet.exe remove package $_ }
    Pop-Location
}

dotnet nuget locals http-cache --clear
Get-ChildItem -Include "*.csproj", "*.fsproj" -Recurse `
| Select-String "<PackageReference Include=`"$packageNamePattern`"" -List `
| ForEach-Object { RemovePackages $_.Path }
