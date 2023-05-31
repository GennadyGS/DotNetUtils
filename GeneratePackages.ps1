param (
    $sourcePath,
    $outputPath = ".",
    $configuration = "Debug",
    $prerelease = $true,
    $versionsFile
)

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
$normalizedSourcePath = [RegEx]::Replace($establishedSourcePath, "`\+", "/").
    Replace("\", "/").
    TrimEnd("/").
    ToLower()

$versionsFile ??= "$PSScriptRoot/versions.json"

$version = GetAndIncrementVersionFromFile $versionsFile $normalizedSourcePath

$versionWithSuffix = ([System.Convert]::ToBoolean($prerelease)) ? $version + "-alpha" : $version

Write-Host "Generating packages from $sourcePath ..." -ForegroundColor $commandColor
RunAndLogCommand dotnet pack $sourcePath `
    --configuration $configuration `
    -o $outputPath `
    /p:Version=$versionWithSuffix `
    /p:PackageVersion=$versionWithSuffix `
    /p:GeneratePackageOnBuild=false
