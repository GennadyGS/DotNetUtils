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

if (!$releaseSourcePaths -and !$prereleaseSourcePaths) { return }

foreach ($sourcePath in [Linq.Enumerable]::Reverse([string[]]$releaseSourcePaths ?? @())) {
    & $PSScriptRoot/UpdatePackagesFrom.ps1 `
        $sourcePath `
        -targetPath $targetPath `
        -framework $framework
}

foreach ($sourcePath in [Linq.Enumerable]::Reverse([string[]]$prereleaseSourcePaths ?? @())) {
    & $PSScriptRoot/UpdatePackagesFrom.ps1 `
        $sourcePath `
        -targetPath $targetPath `
        -framework $framework `
        -prerelease
}

Push-Location $targetPath
if ($test) { RunAndLogCommand dotnet test }
elseif ($build) { RunAndLogCommand dotnet build }
Pop-Location