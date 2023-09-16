Function ResolveProjectProperty($projectFilePath, $propertyName) {
    if (!(Test-Path $projectFilePath -PathType Leaf)) {
        throw "File $projectFilePath does not exist"
    }

    $projectFileName = Split-Path $projectFilePath -Leaf
    $predefinedProperties = @{
        MSBuildProjectName = [IO.Path]::GetFileNameWithoutExtension($projectFileName)
    }

    $compositeContent = GetProjectCompositeContent $projectFilePath
    [array]::Reverse($compositeContent)

    Function GetProperty($propertyName) {
        if ($predefinedProperties.ContainsKey($propertyName)) {
            return $predefinedProperties[$propertyName]
        }

        $propertyPattern = "<$propertyName>([^\[]+)</$propertyName>"
        $originalPropertyName = [regex]::match($compositeContent, $propertyPattern).Groups[1].Value
        [regex]::replace(
            $originalPropertyName,
            "\$\((\w+)\)",
            { param($match) GetProperty($match.Groups[1].Value) })
    }

    GetProperty $propertyName
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
    $result
}