# Generates test tasks for samples.

Get-Item ../samples-PowerShell/*.ps1 | .{process{
	Add-BuildTask -Name:$_.Name -Data:$_ -Jobs:{
		& $Task.Data
	}
}}
