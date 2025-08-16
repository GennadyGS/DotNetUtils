param (
    $sourcePath,
    $outputPath,
    [Alias("c")] $configuration = "Debug",
    $prerelease = $true,
    $versionsFile
)

. $PSScriptRoot\Common.ps1

Function IncrementVersion {
    param ($versionString)
    try {
        $version = [version]$versionString
    }
    catch {
        throw $_
    }
    return "$($version.Major).$($version.Minor).$($version.Build).$($version.Revision + 1)"
}

Function GetAndIncrementVersion {
    param ($versions, $key)
    $storedVersion = $versions.$key
    $currentVersion = $storedVersion ?? "99.0.0.1"
    $versions.$key = IncrementVersion $currentVersion
    return $currentVersion
}

Function GetAndIncrementVersionFromFile {
    param ($fileName, $key)

    $versions = (Test-Path $fileName -PathType Leaf) `
        ? (Get-Content $fileName | ConvertFrom-Json -AsHashtable) `
        : @{}

    $result = GetAndIncrementVersion $versions $key
    $versions | ConvertTo-Json | Out-File $fileName
    return $result
}

$establishedSourcePath = $sourcePath `
    ? [IO.Path]::GetFullPath($sourcePath) `
    : (Get-Location).Path
$establishedSourceDirectoryPath = GetDirectoryPath $establishedSourcePath

$canonicalSourcePath = [RegEx]::Replace($establishedSourcePath, "`\+", "/").
    Replace("\", "/").
    TrimEnd("/").
    ToLower()
$versionsFile ??= "$PSScriptRoot/versions.json"
$version = GetAndIncrementVersionFromFile $versionsFile $canonicalSourcePath

$versionWithSuffix = ([System.Convert]::ToBoolean($prerelease)) ? $version + "-alpha" : $version

WriteHighlighted "Generating packages from $establishedSourcePath ..."
Push-Location $establishedSourceDirectoryPath
RunCommandWithLog dotnet pack $establishedSourcePath `
    --configuration $configuration `
    -o ($outputPath ?? $localNugetSourcePath) `
    /p:Version=$versionWithSuffix `
    /p:PackageVersion=$versionWithSuffix `
    /p:GeneratePackageOnBuild=false
Pop-Location