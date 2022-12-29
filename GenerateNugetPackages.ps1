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
    param ($versions, $key)
    $storedVersion = $versions.$key
    $currentVersion = if ($storedVersion) { $storedVersion } else { "0.0.0.1" }
    $versions.$key = IncrementVersion $currentVersion
    return $currentVersion
}

Function ConvertTo-HashTable{
    param ([Parameter(Mandatory = $true, ValueFromPipeline = $true)] $object)
    $result = @{}
    $object.psobject.properties | ForEach-Object { $result[$_.Name] = $_.Value }
    return $result
}

Function GetAndIncrementVersionFromFile {
    param ($fileName)

    if (Test-Path $fileName -PathType Leaf) {
        $versions = Get-Content $fileName | ConvertFrom-Json | ConvertTo-HashTable
    }
    else {
        $versions = @{}
    }

    if ($project) {
        $projectOrPath = [IO.Path]::GetFullPath($project).TrimEnd("/\")
    }
    else {
        $projectOrPath = (Get-Location).Path
    }

    $result = GetAndIncrementVersion $versions $projectOrPath
    $versions | ConvertTo-Json | Out-File $fileName
    return $result
}

$version = GetAndIncrementVersionFromFile "$PSScriptRoot/versions.json"

If ([System.Convert]::ToBoolean($prerelease)) {
    $versionWithSuffix = $version + "-alpha"
}
else {
    $versionWithSuffix = $version
}

. dotnet pack $project `
    --configuration $configuration `
    -o $outputPath `
    /p:PackageVersion=$versionWithSuffix
