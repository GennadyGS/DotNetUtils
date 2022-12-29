param (
    $project,
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
    param ($versions, [string] $key)
    $caseInsensitiveKey = $key.ToLower()
    $storedVersion = $versions.$caseInsensitiveKey
    $currentVersion = $storedVersion ?? "0.0.0.1"
    $versions.$caseInsensitiveKey = IncrementVersion $currentVersion
    return $currentVersion
}

Function GetAndIncrementVersionFromFile {
    param ($fileName)

    $versions = (Test-Path $fileName -PathType Leaf) `
        ? (Get-Content $fileName | ConvertFrom-Json -AsHashtable) `
        : @{}

    $projectOrPath = $project `
        ? [IO.Path]::GetFullPath($project).TrimEnd("/\") `
        : (Get-Location).Path

    $result = GetAndIncrementVersion $versions $projectOrPath
    $versions | ConvertTo-Json | Out-File $fileName
    return $result
}

$version = GetAndIncrementVersionFromFile "$PSScriptRoot/versions.json"

$versionWithSuffix = ([System.Convert]::ToBoolean($prerelease)) ? $version + "-alpha" : $version

. dotnet pack $project `
    --configuration $configuration `
    -o $outputPath `
    /p:PackageVersion=$versionWithSuffix
