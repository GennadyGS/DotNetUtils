param (
    $projectOrPath,
    $outputPath = ".",
    $configuration = "Debug",
    $prerelease = "true"
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

$establishedProjectOrPath = $projectOrPath `
    ? [IO.Path]::GetFullPath($projectOrPath) `
    : (Get-Location).Path
$normalizedProjectOrPath = [RegEx]::Replace($establishedProjectOrPath, "`\+", "/").
    Replace("\", "/").
    TrimEnd("/").
    ToLower()

$version = GetAndIncrementVersionFromFile "$PSScriptRoot/versions.json" $normalizedProjectOrPath

$versionWithSuffix = ([System.Convert]::ToBoolean($prerelease)) ? $version + "-alpha" : $version

. dotnet pack $projectOrPath `
    --configuration $configuration `
    -o $outputPath `
    /p:PackageVersion=$versionWithSuffix `
    /p:GeneratePackageOnBuild=false
