param(
    $solutionOrDirectory,
    $version,
    $framework,
    $source,
    [switch][Alias("pre")]$prerelease
)

Function TryGetAssemblyName($projectRelativePath) {
    $fullPath = Join-Path $solutionDirectory $projectRelativePath
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

$solutionDirectory = (Test-Path $solutionOrDirectory -PathType Leaf) `
    ? [IO.Path]::GetDirectoryName($solutionOrDirectory) `
    : $solutionOrDirectory

$packageNames = . dotnet sln $solutionOrDirectory list `
    | ForEach-Object { TryGetAssemblyName $_ }
    | Where-Object { $_ }
    | Sort-Object

$packageNamePattern = ($packageNames | ForEach-Object { [Regex]::Escape($_) }) -join "|"

. $PSScriptRoot/UpdateAllPackages.ps1 `
    $packageNamePattern `
    -match `
    -version=$version `
    -framework=$framework `
    -source=$source `
    -prerelease:$prerelease
