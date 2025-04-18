# Generates test tasks for samples.

Get-Item ../samples-PowerShell/*.ps1 | .{process{
	if ($PSEdition -eq 'Desktop' -and $_.Name -in @('DataFrame.ps1')) {
		return
	}

	Add-BuildTask $_.Name -Data $_ {
		& $Task.Data
	}
}}
