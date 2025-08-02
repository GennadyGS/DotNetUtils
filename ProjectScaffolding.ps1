param(
    [Parameter(Mandatory=$true)] [string]$ProjectName,
    [ValidateSet("library", "cli")]
    [string]$ProjectType = "library",
    [string]$Author = "Your Name",
    [string]$Company = "Your Company",
    [string]$Version = "1.0.0"
)

$root = Join-Path $pwd $ProjectName
$src = Join-Path $root "src\$ProjectName"
$test = Join-Path $root "tests\$ProjectName.Tests"
$workflow = Join-Path $root ".github\workflows"
$sample = Join-Path $root "samples\SampleApp"

# Create directory structure
New-Item -ItemType Directory -Force -Path $src, $test, $workflow, $sample | Out-Null

# Create main project and set metadata
if ($ProjectType -eq "library") {
    dotnet new classlib -n $ProjectName -o $src
    $metadata = @{
        PackageId = $ProjectName
        Version = $Version
        Authors = $Author
        Company = $Company
        PackageDescription = "$ProjectName is a modern .NET library for [describe purpose]."
        RepositoryUrl = "https://github.com/your-org/$ProjectName"
        RepositoryType = "git"
        PackageTags = "$ProjectName;dotnet;nuget"
        GeneratePackageOnBuild = "true"
    }
    $readme = @"
# $ProjectName

NuGet package: [![NuGet](https://img.shields.io/nuget/v/$ProjectName.svg)](https://www.nuget.org/packages/$ProjectName)

## Install

```sh
dotnet add package $ProjectName
```

## Build & Test

```sh
dotnet build
dotnet test
```
"@
    $ci = @"
name: .NET CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: 8.x
      - name: Restore
        run: dotnet restore
      - name: Build
        run: dotnet build --no-restore --configuration Release
      - name: Test
        run: dotnet test --no-build --configuration Release
      - name: Pack
        run: dotnet pack src/$ProjectName --no-build --configuration Release --output nupkgs
"@
    $finalMessage = "🎉 .NET library '$ProjectName' structure created, NuGet-ready, and Git tagged with version $Version"
} elseif ($ProjectType -eq "cli") {
    dotnet new console -n $ProjectName -o $src
    $metadata = @{
        Version = $Version
        Authors = $Author
        Company = $Company
    }
    $readme = @"
# $ProjectName

Command-line tool built with .NET.

## Usage

```sh
dotnet run --project src/$ProjectName -- [args]
```

## Build & Test

```sh
dotnet build
dotnet test
```
"@
    $ci = @"
name: .NET CLI CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: 8.x
      - name: Restore
        run: dotnet restore
      - name: Build
        run: dotnet build --no-restore --configuration Release
      - name: Test
        run: dotnet test --no-build --configuration Release
      - name: Publish
        run: dotnet publish src/$ProjectName --no-build --configuration Release --output publish
"@
    $finalMessage = "🚀 .NET CLI tool '$ProjectName' structure created and Git tagged with version $Version"
}

# Add metadata to .csproj
$csprojPath = Join-Path $src "$ProjectName.csproj"
[xml]$csproj = Get-Content $csprojPath
$propertyGroup = $csproj.Project.PropertyGroup
foreach ($key in $metadata.Keys) {
    $elem = $csproj.CreateElement($key)
    $elem.InnerText = $metadata[$key]
    $propertyGroup.AppendChild($elem) | Out-Null
}
$csproj.Save($csprojPath)

# Create test project
dotnet new xunit -n "$ProjectName.Tests" -o $test
dotnet add "$test" reference "$src"

# README
$readme | Out-File -Encoding utf8 "$root\README.md"

# LICENSE
@"
MIT License

Copyright (c) $(Get-Date -Format yyyy)

Permission is hereby granted, free of charge, to any person obtaining a copy...
"@ | Out-File -Encoding utf8 "$root\LICENSE"

# CHANGELOG
@"
# Changelog

## [$Version] - $(Get-Date -Format yyyy-MM-dd)

- Initial release
"@ | Out-File -Encoding utf8 "$root\CHANGELOG.md"

# GitHub Actions CI workflow
$ci | Out-File -Encoding utf8 "$workflow\ci.yml"

# Initialize Git and tag version
Set-Location $root
git init
git add .
git commit -m "Initial commit for $ProjectName v$Version"
git tag "v$Version"
Set-Location ..

Write-Host $finalMessage
