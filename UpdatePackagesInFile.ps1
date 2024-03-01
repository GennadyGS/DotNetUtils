param (
    [Parameter(Mandatory=$true)]$filePath,
    [Alias("f")] $framework="net6.0",
    [switch] $keepTempFile
)

$packageReferencesItemGroupRegex = "(?s)<ItemGroup>\s*<PackageReference.*?<\/ItemGroup>"

Function GetFileContent($filePath) {
    If (!(Test-Path $filePath -PathType Leaf)) { throw "File $filePath is not found." }
    Get-Content $filePath -Raw
}

Function GetPackageReferencesContent($content) {
    $match = [regex]::match($content, $packageReferencesItemGroupRegex)
    If (!$match.Success) { throw "Cannot find <ItemGroup> element." }
    $match.Value
}

Function GetPackageReferencesContentFromFile($filePath) {
    $content = GetFileContent $filePath
    GetPackageReferencesContent $content
}

If (!(Test-Path $filePath -PathType Leaf)) { throw "File $filePath is not found." }
$content = GetFileContent $filePath
$packageReferencesContent = GetPackageReferencesContent $content

$tempProjectFileContent = @"
<Project Sdk="Microsoft.NET.Sdk">
    <PropertyGroup>
        <TargetFramework>$framework</TargetFramework>
    </PropertyGroup>
    $packageReferencesContent
</Project>
"@

$tempProjectDirectoryPath = Join-Path $Env:Temp (New-Guid)
New-Item -Type Directory -Path $tempProjectDirectoryPath | Out-Null
$tempProjectFilePath = Join-Path $tempProjectDirectoryPath "tempProject.csproj"
$tempProjectFileContent | Out-File $tempProjectFilePath -NoNewline
"Temp project file is created: $tempProjectFilePath"

& $PsScriptRoot/UpdatePackages.ps1 -targetPath $tempProjectDirectoryPath -f $framework

$updatedPackageReferencesContent = GetPackageReferencesContentFromFile $tempProjectFilePath
$updatedContent = $content -replace $packageReferencesItemGroupRegex, $updatedPackageReferencesContent
$updatedContent | Out-File $filePath -NoNewline

If (!$keepTempFile) {
    Remove-Item -Recurse -Force $tempProjectDirectoryPath
}