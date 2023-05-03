param (
    [string[]] $projects,
    $outputPath = ".",
    $configuration = "Debug",
    $framework,
    $prerelease = $true,
    $generatePackagesScriptName = "GeneratePackages.ps1"
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
    -generatePackagesScriptName $generatePackagesScriptName

foreach ($dependencyProject in $dependencyProjects) {
    & $PSScriptRoot/UpdatePackagesFrom.ps1 `
        $dependencyProject `
        -target $primaryProject `
        -framework $framework `
        -prerelease:$prerelease
}

if ($prerelease) {
    & $PSScriptRoot/$generatePackagesScriptName `
    $primaryProject `
    -outputPath $outputPath `
    -configuration $configuration `
    -prerelease $prerelease
}
