# Copyright 2015 ThoughtWorks, Inc.

# This file is part of Gauge-CSharp.

# Gauge-CSharp is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Gauge-CSharp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Gauge-CSharp.  If not, see <http://www.gnu.org/licenses/>.

# Clean the artifacts directory

Remove-Item "$($pwd)\artifacts*" -recurse -force

# Build everything

& "$(Split-Path $MyInvocation.MyCommand.Path)\build.ps1"

$nugetInstallScript= {param($outputPath, $nugetDir, $projectPath)
    $nuget = "$($pwd)\.nuget\NuGet.exe"
    $env:OutDir=$outputPath # required for nuget to pick up the file from this location
    &$nuget pack "$($projectPath)" /p Configuration=release -OutputDirectory "$($nugetDir)" -Verbosity detailed -ExcludeEmptyDirectories
}

$nugetDir = "$($pwd)\artifacts"
New-Item -Itemtype directory $nugetDir -Force

# Package the Lib, output is Gauge.CSharp.Lib.nupkg
$buildOutputPath= "$($pwd)\artifacts\gauge-csharp-lib"
$libProjectPath = "Lib\Gauge.CSharp.Lib.csproj"
Invoke-Command -ScriptBlock $nugetInstallScript -ArgumentList $buildOutputPath, $nugetDir, $libProjectPath

# Package Core, output is Gauge.CSharp.Core.nupkg
$buildOutputPath= "$($pwd)\artifacts\gauge-csharp-core"
$coreProjectPath = "Core\Gauge.CSharp.Core.csproj"
Invoke-Command -ScriptBlock $nugetInstallScript -ArgumentList $buildOutputPath, $nugetDir, $coreProjectPath

# Now, package the runner
$outputDir= "$($pwd)\artifacts\gauge-csharp"

$outputPath= "$($pwd)\artifacts\gauge-csharp\bin"
$skelDir="$($outputDir)\skel"
$skelPropertiesDir = "$($skelDir)\Properties"

@($skelDir, $skelPropertiesDir) | %{ New-Item -Itemtype directory $_ -Force}

Write-host "Copying Skeleton files for Gauge CSharp project"

# Copy the skeleton files
Copy-Item "$($pwd)\Gauge.Project.Skel\AssemblyInfo.cs" -Destination $skelPropertiesDir -Force
Copy-Item "$($pwd)\Gauge.Project.Skel\Gauge.Spec.csproj" -Destination $skelDir -Force
Copy-Item "$($pwd)\Gauge.Project.Skel\StepImplementation.cs" -Destination $skelDir -Force
Copy-Item "$($pwd)\Gauge.Project.Skel\packages.config" -Destination $skelDir -Force
Copy-Item "$($pwd)\Gauge.Project.Skel\Gauge.Spec.sln" -Destination $skelDir -Force
Copy-Item "$($pwd)\Runner\csharp.json" -Destination $outputDir -Force

Import-Module Pscx

# zip!
$zipScript= {
    set-location $outputDir
    $version=(Get-Item "$($outputPath)\Gauge.CSharp.Runner.exe").VersionInfo.ProductVersion
    gci -recurse | Write-Zip -OutputPath "$(Split-Path $outputDir)\gauge-csharp-$($version).zip"
}

Invoke-Command -ScriptBlock $zipScript
