param (
    $targetPath,
    [string[]] $prereleaseSourcePaths = @(),
    [string[]] $releaseSourcePaths = @(),
    $packagesOutputPath,
    [Alias("c")] $configuration = "Debug",
    $framework,
    [switch] $build,
    [switch] $test
)

. $PSScriptRoot\Common.ps1

if ($prereleaseSourcePaths) {
    $firstPrereleaseSourcePath = $prereleaseSourcePaths[0]
    $restPrereleaseSourcePath = $prereleaseSourcePaths | Select-Object -Skip 1

    & $PSCommandPath `
        $firstPrereleaseSourcePath `
        $restPrereleaseSourcePath `
        $releaseSourcePaths `
        -packagesOutputPath ($packagesOutputPath ?? $localNugetSourcePath) `
        -configuration $configuration `
        -framework $framework `
        -build:$build `
        -test:$test

    & $PSScriptRoot\GeneratePackages.ps1 `
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
if ($test) { RunAndLogCommand dotnet test -c $configuration }
elseif ($build) { RunAndLogCommand dotnet build -c $configuration }
Pop-Location