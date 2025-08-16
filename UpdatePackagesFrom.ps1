param(
    [Parameter(Mandatory=$true)] $sourcePath,
    $targetPath = '.',
    $packageSource,
    [Alias("v")] $version,
    $framework,
    [switch] $build,
    [switch] $test,
    [switch] [Alias("pre")] $prerelease
)

. $PSScriptRoot\Common.ps1

Function TryGetPackageAssemblyName($projectFilePath) {
    if ((ResolveProjectProperty $projectFilePath "IsPackable") -eq "false") { return $null }
    ResolveProjectProperty $projectFilePath "AssemblyName"
}

$sourceDirectoryPath = GetDirectoryPath $sourcePath

if (!(Test-Path $sourceDirectoryPath -PathType Container)) {
    throw "Source directory '$sourceDirectoryPath' does not exist."
}

$packageNames = & dotnet sln $sourcePath list `
    | Select-Object -Skip 2
    | ForEach-Object { TryGetPackageAssemblyName (Join-Path $sourcePath $_) }
    | Where-Object { $_ }
    | Sort-Object

$packageNamePattern = ($packageNames | ForEach-Object { [Regex]::Escape($_) }) -join "|"

WriteHighlighted "Updating packages in $targetPath from $sourcePath by pattern $packageNamePattern ..."
. $PSScriptRoot/UpdatePackages.ps1 `
    $packageNamePattern `
    -targetPath $targetPath `
    -packageSource $packageSource `
    -version $version `
    -framework $framework `
    -build:$build `
    -test:$test `
    -prerelease:$prerelease `
    -match
