param (
    $targetPath,
    [string[]] $prereleaseSourcePaths = @(),
    [string[]] $releaseSourcePaths = @(),
    $packagesOutputPath = ".",
    $configuration = "Debug",
    $framework,
    $generatePackagesScriptName,
    [switch] $build,
    [switch] $test
)

$generatePackagesScriptName ??= "$PSScriptRoot\GeneratePackages.ps1"

if ($prereleaseSourcePaths) {
    $firstPrereleaseSourcePath = $prereleaseSourcePaths[0]
    $restPrereleaseSourcePath = $prereleaseSourcePaths | Select-Object -Skip 1

    & $PSCommandPath `
        $firstPrereleaseSourcePath `
        $restPrereleaseSourcePath `
        $releaseSourcePaths `
        -packagesOutputPath $packagesOutputPath `
        -configuration $configuration `
        -framework $framework `
        -generatePackagesScriptName $generatePackagesScriptName `
        -build:$build `
        -test:$test

    & $generatePackagesScriptName `
        $firstPrereleaseSourcePath `
        -outputPath $packagesOutputPath `
        -configuration $configuration
}

foreach ($sourcePath in $releaseSourcePaths) {
    & $PSScriptRoot/UpdatePackagesFrom.ps1 `
        $sourcePath `
        -targetPath $targetPath `
        -framework $framework `
        -build:$build `
        -test:$test
}

foreach ($sourcePath in $prereleaseSourcePaths) {
    & $PSScriptRoot/UpdatePackagesFrom.ps1 `
        $sourcePath `
        -targetPath $targetPath `
        -framework $framework `
        -prerelease `
        -build:$build `
        -test:$test
}
