Function ResolveProjectProperty($projectFilePath, $propertyName) {
    if (!(Test-Path $projectFilePath -PathType Leaf)) {
        throw "File $projectFilePath does not exist"
    }

    $compositeContent = GetProjectCompositeContent $projectFilePath
    [array]::Reverse($compositeContent)

    Function GetProperty($propertyName) {
        $propertyPattern = "<$propertyName>([^\<]+)</$propertyName>"
        $originalPropertyName = [regex]::match($compositeContent, $propertyPattern).Groups[1].Value
        [regex]::replace(
            $originalPropertyName,
            "\$\((\w+)\)",
            { param($match) GetProperty($match.Groups[1].Value) })
    }

    $result = GetProperty $propertyName
    if (!$result) { return $null }
    $result
}

Function GetProjectCompositeContent($projectFilePath) {
    $result = Get-Content -Path $projectFilePath
    $path = Split-Path $projectFilePath -Parent
    while ($path) {
        $sharedProjectFilePath = Join-Path $path "Directory.Build.props"
        if (Test-Path $sharedProjectFilePath -PathType Leaf) {
            $result = (Get-Content -Path $sharedProjectFilePath) + $result
        }
        if (Test-Path (Join-Path $path "*.sln") -PathType Leaf) {
            break
        }
        $path = Split-Path $path -Parent
    }
    (GetPredefinedProjectContent $projectFilePath) + $result
}

Function GetPredefinedProjectContent($projectFilePath) {
    $projectFileName = Split-Path $projectFilePath -Leaf
    $projectName = [IO.Path]::GetFileNameWithoutExtension($projectFileName)
    $predefinedProperties = @{
        MSBuildProjectName = $projectName
        AssemblyName = $projectName
    }
    PropertiesToXml $predefinedProperties
}

Function PropertiesToXml($properties) {
    $body = $properties.Keys | ForEach-Object { "<$_>$($properties[$_])</$_>" }
    "<PropertyGroup>$body</PropertyGroup>"
}