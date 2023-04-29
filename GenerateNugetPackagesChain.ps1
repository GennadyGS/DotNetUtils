param (
    [string[]] $projects,
    $outputPath = ".",
    $configuration = "Debug",
    $framework,
    $prerelease = $true,
    $generateNugetPackagesScriptName = "GenerateNugetPackages.ps1"
)

if (!($projects)) {
    return
}

$primaryProject = $projects[0]
$dependencyProjects = $projects | Select-Object -Skip 1

& $PSCommandPath `
    $dependencyProjects `
    -outputPath $outputPath `
    -configuration $configuration `
    -framework $framework `
    -prerelease $prerelease `
    -generateNugetPackagesScriptName $generateNugetPackagesScriptName

foreach ($dependencyProject in $dependencyProjects) {
    & $PSScriptRoot/UpdateAllPackagesFrom.ps1 `
        $dependencyProject `
        -target $primaryProject `
        -framework $framework `
        -prerelease:$prerelease
}

& $PSScriptRoot/$generateNugetPackagesScriptName `
    $primaryProject `
    -outputPath $outputPath `
    -configuration $configuration `
    -prerelease $prerelease
