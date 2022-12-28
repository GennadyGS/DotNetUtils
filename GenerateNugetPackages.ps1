param (
    $project,
    $outputPath = ".",
    $configuration = "Debug",
    $prerelease = "true"
)

Function IncrementVersion {
    param ($version)
    $typedVersion = [version]$version
    return "{0}.{1}.{2}.{3}" `
        -f $typedVersion.Major, $typedVersion.Minor, $typedVersion.Build, ($typedVersion.Revision + 1)
}

Function GetAndIncrementVersion {
    param ($versions, $key)
    $storedVersion = $versions.$key
    $currentVersion = if ($storedVersion) { $storedVersion } else { "0.0.0.1" }
    $versions.$key = IncrementVersion $currentVersion
    return $currentVersion
}

Function GetAndIncrementVersionFromFile {
    param ($fileName)

    if (Test-Path $fileName -PathType Leaf) {
        $versionsObject = Get-Content $fileName | ConvertFrom-Json
        $versions = @{}
        $versionsObject.psobject.properties | ForEach-Object { $versions[$_.Name] = $_.Value }
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
