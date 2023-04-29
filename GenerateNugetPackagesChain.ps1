param (
    [string[]]$projects,
    $outputPath = ".",
    $configuration = "Debug",
    $framework,
    $prerelease = $true
)

if (!($projects)) {
    return
}

$primaryProject = $projects[0]
$dependencyProjects = $projects | Select-Object -Skip 1

& $PSScriptRoot/GenerateNugetPackagesChain.ps1 `
    $dependencyProjects `
    -outputPath $outputPath `
    -configuration $configuration `
    -framework $framework `
    -prerelease $prerelease

foreach ($dependencyProject in $dependencyProjects) {
    & $PSScriptRoot/UpdateAllPackagesFrom.ps1 `
        $dependencyProject `
        -target $primaryProject `
        -source $outputPath `
        -framework $framework `
        -prerelease:$prerelease
}

& $PSScriptRoot/GenerateNugetPackages.ps1 `
    $primaryProject `
    -outputPath $outputPath `
    -configuration $configuration `
    -prerelease $prerelease
