@{
	Author = 'Roman Kuzmin'
	ModuleVersion = '0.0.0'
	Description = 'FarNet.SQLite cmdlets'
	Copyright = 'Copyright (c) Roman Kuzmin'
	GUID = 'b46a23d4-b293-47be-9f8e-c5093e6fd5d8'

	PowerShellVersion = '5.1'
	RootModule = 'PS.FarNet.SQLite.dll'
	RequiredAssemblies = 'FarNet.SQLite.dll', 'System.Data.SQLite.dll'

	AliasesToExport = @()
	FunctionsToExport = @()
	VariablesToExport = @()
	CmdletsToExport = @(
		'Open-SQLite'
		'Get-SQLite'
		'Set-SQLite'
		'Close-SQLite'
		'Complete-SQLite'
		'New-SQLiteCommand'
		'New-SQLiteParameter'
		'Register-SQLiteFunction'
	)
}
