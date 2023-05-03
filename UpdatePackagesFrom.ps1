param(
    $sourcePath,
    $version,
    $targetPath = '.',
    $packageSource,
    $framework,
    [switch][Alias("pre")]$prerelease
)

Function TryGetAssemblyName($projectRelativePath) {
    $fullPath = Join-Path $sourceDirectoryPath $projectRelativePath
    if (!(Test-Path $fullPath -PathType Leaf)) {
        return $null
    }
    $content = [string](Get-Content $fullPath)
    if ($content -match "<IsPackable>false</IsPackable>") {
        return $null
    }
    $baseProjectName = [IO.Path]::GetFileNameWithoutExtension($projectRelativePath)
    $content -match "<AssemblyName>(?<assemblyName>.*)</AssemblyName>" `
        ? $Matches["assemblyName"].Replace("`$(MSBuildProjectName)", $baseProjectName) `
        : $baseProjectName
}

$sourceDirectoryPath = (Test-Path $sourcePath -PathType Leaf) `
    ? [IO.Path]::GetDirectoryName($sourcePath) `
    : $sourcePath

$packageNames = . dotnet sln $sourcePath list `
    | ForEach-Object { TryGetAssemblyName $_ }
    | Where-Object { $_ }
    | Sort-Object

$packageNamePattern = ($packageNames | ForEach-Object { [Regex]::Escape($_) }) -join "|"

. $PSScriptRoot/UpdatePackages.ps1 `
    $packageNamePattern `
    -version $version `
    -targetPath $targetPath `
    -packageSource $packageSource `
    -framework $framework `
    -prerelease:$prerelease `
    -match
