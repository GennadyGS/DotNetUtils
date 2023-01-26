param (
    $targetDirectoryPath = "."
)

$targetPath = Join-Path $targetDirectoryPath NuGet.Config
if (Test-Path $targetPath) {
    Remove-Item $targetPath -Force
    Write-Output "File '$targetPath' is successfully removed."
}
else {
    Write-Output "File '$targetPath' does not exist."
}
