<#
.Synopsis
	Build script, https://github.com/nightroman/Invoke-Build
#>

param(
	$Configuration = (property Configuration Release),
	$FarHome = (property FarHome C:\Bin\Far\x64)
)

Set-StrictMode -Version 3
$ModuleName = 'FarNet.SQLite'
$ModuleRoot = "$FarHome\FarNet\Lib\$ModuleName"
$Description = 'System.Data.SQLite package for FarNet.'

task build meta, {
	Set-Location src
	exec { dotnet build -c $Configuration }
}

task copy {
	exec { robocopy FarNet.SQLite $ModuleRoot } (0..3)
}

task publish copy, {
	Set-Location src
	$v1 = (Select-Xml '//PackageReference[@Include="Stub.System.Data.SQLite.Core.NetStandard"]' FarNet.SQLite.csproj).Node.Version

	Copy-Item -Destination $ModuleRoot @(
		"bin\$Configuration\netstandard2.0\FarNet.SQLite.dll"
		"bin\$Configuration\netstandard2.0\FarNet.SQLite.xml"
		"$HOME\.nuget\packages\Stub.System.Data.SQLite.Core.NetStandard\$v1\lib\netstandard2.0\System.Data.SQLite.dll"
		"$HOME\.nuget\packages\Stub.System.Data.SQLite.Core.NetStandard\$v1\lib\netstandard2.0\System.Data.SQLite.xml"
		"$HOME\.nuget\packages\Stub.System.Data.SQLite.Core.NetStandard\$v1\runtimes\win-x64\native\SQLite.Interop.dll"
	)
}

task clean {
	remove src\bin, src\obj, README.htm, *.nupkg, z
}

task version {
	($script:Version = switch -Regex -File Release-Notes.md {'##\s+v(\d+\.\d+\.\d+)' {$Matches[1]; break} })
}

task markdown version, {
	assert (Test-Path $env:MarkdownCss)
	exec { pandoc.exe @(
		'README.md'
		'--output=README.htm'
		'--from=gfm'
		'--self-contained', "--css=$env:MarkdownCss"
		'--standalone', "--metadata=pagetitle=$ModuleName $Version"
	)}
}

task meta -Inputs .build.ps1, Release-Notes.md -Outputs src\Directory.Build.props -Jobs version, {
	Set-Content src\Directory.Build.props @"
<Project>
	<PropertyGroup>
		<Company>https://github.com/nightroman/$ModuleName</Company>
		<Copyright>Copyright (c) Roman Kuzmin</Copyright>
		<Description>$Description</Description>
		<Product>$ModuleName</Product>
		<Version>$Version</Version>
		<FileVersion>$Version</FileVersion>
		<AssemblyVersion>$Version</AssemblyVersion>
	</PropertyGroup>
</Project>
"@
}

task package markdown, version, {
	remove z
	$toModule = mkdir "z\tools\FarHome\FarNet\Lib\$ModuleName"

	exec { robocopy $ModuleRoot $toModule /s /xf *.pdb SQLite.Interop.dll } 1
	equals 7 (Get-ChildItem $toModule -Recurse).Count

	Copy-Item -Destination $toModule @(
		"README.htm"
		"LICENSE"
	)

	$v1 = (Select-Xml '//PackageReference[@Include="Stub.System.Data.SQLite.Core.NetStandard"]' src\FarNet.SQLite.csproj).Node.Version
	foreach($x in 'x64', 'x86') {
		$to = mkdir "z\tools\FarHome.$x\FarNet\Lib\$ModuleName"
		Copy-Item "$HOME\.nuget\packages\Stub.System.Data.SQLite.Core.NetStandard\$v1\runtimes\win-$x\native\SQLite.Interop.dll" $to
	}

	Import-Module PsdKit
	$xml = Import-PsdXml $toModule\$ModuleName.psd1
	Set-Psd $xml $Version 'Data/Table/Item[@Key="ModuleVersion"]'
	Export-PsdXml $toModule\$ModuleName.psd1 $xml
}

task nuget package, version, {
	($dllVersion = (Get-Item "$ModuleRoot\$ModuleName.dll").VersionInfo.FileVersion.ToString())
	equals $dllVersion $Version

	$Description = @"
$Description

---

To install FarNet packages, follow these steps:

https://github.com/nightroman/FarNet#readme

---
"@

	Set-Content z\Package.nuspec @"
<?xml version="1.0"?>
<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">
	<metadata>
		<id>$ModuleName</id>
		<version>$Version</version>
		<authors>Roman Kuzmin</authors>
		<owners>Roman Kuzmin</owners>
		<projectUrl>https://github.com/nightroman/$ModuleName</projectUrl>
		<license type="expression">MIT</license>
		<description>$Description</description>
		<releaseNotes>https://github.com/nightroman/$ModuleName/blob/main/Release-Notes.md</releaseNotes>
		<tags>FarManager FarNet SQLite Database</tags>
	</metadata>
</package>
"@

	exec { NuGet.exe pack z\Package.nuspec }
}

task test {
	Invoke-Build ** tests
}

task . build, clean
