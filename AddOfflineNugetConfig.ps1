param (
    $targetDirectoryPath
)

$sourcePath = "$PSScriptRoot/NuGet_Offline.Config"
$targetPath = Join-Path ($targetDirectoryPath ?? ".") NuGet.Config
if (!(Test-Path $targetPath)) {
    Copy-Item $sourcePath $targetPath
    Write-Output "File '$targetPath' is successfully added."
}
else {
    Write-Error "File '$targetPath' already exists."
}
