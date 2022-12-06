$ErrorActionPreference=1

#.ExternalHelp FarNet.SQLite-Help.xml
function Open-SQLite {
	[CmdletBinding()]
	param(
		[Parameter(Position=0)]
		[string]$Database
		,
		[Parameter(Position=1)]
		[string]$Options
		,
		[switch]$CreateFile
		,
		[switch]$Transaction
		,
		[switch]$AllowNestedTransactions
		,
		[switch]$ForeignKeys
		,
		[switch]$ReadOnly
		,
		[string]$Variable = 'db'
	)

	if ($Database) {
		if ($Database -ne ':memory:') {
			$Database = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Database)
			if ($CreateFile) {
				[System.Data.SQLite.SQLiteConnection]::CreateFile($Database)
			}
		}
	}
	elseif (!$Options) {
		$Database = ':memory:'
	}

	$sb = [System.Data.SQLite.SQLiteConnectionStringBuilder]::new($Options)
	if ($AllowNestedTransactions) {
		$sb.Flags = $sb.Flags -bor [System.Data.SQLite.SQLiteConnectionFlags]::AllowNestedTransactions
	}
	if ($ForeignKeys) {
		$sb.ForeignKeys = $true
	}
	if ($ReadOnly) {
		$sb.ReadOnly = $true
	}

	$db = [System.Data.SQLite.DB]::new($Database, $sb.ConnectionString, $Transaction)
	$PSCmdlet.SessionState.PSVariable.Set($Variable, $db)
}

#.ExternalHelp FarNet.SQLite-Help.xml
function Close-SQLite {
	[CmdletBinding()]
	param(
		[Parameter(Position=0)]
		[System.Data.SQLite.DB]$Database
	)

	if (!$Database -and !($Database = $PSCmdlet.GetVariableValue('db'))) {
		Write-Error 'Expected variable $db or parameter Database.'
	}

	$Database.Dispose()
}

#.ExternalHelp FarNet.SQLite-Help.xml
function Complete-SQLite {
	[CmdletBinding()]
	param(
		[Parameter(Position=0)]
		[System.Data.SQLite.DB]$Database
	)

	if (!$Database -and !($Database = $PSCmdlet.GetVariableValue('db'))) {
		Write-Error 'Expected variable $db or parameter Database.'
	}

	$Database.Commit()
}

#.ExternalHelp FarNet.SQLite-Help.xml
function Set-SQLite {
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[object]$Command
		,
		[Parameter(Position=1)]
		[object[]]$Parameters = @()
		,
		[switch]$Result
		,
		[System.Data.SQLite.DB]$Database
	)

	if (!$Database -and !($Database = $PSCmdlet.GetVariableValue('db'))) {
		Write-Error 'Expected variable $db or parameter Database.'
	}

	if ($Command -is [System.Data.SQLite.SQLiteCommand]) {
		if ($Parameters) {
			Write-Error 'Parameters are not used with SQLiteCommand command.'
		}

		if ($Result) {
			$Database.ExecuteNonQuery($Command)
		}
		else {
			$Database.Execute($Command)
		}
	}
	else {
		if ($Result) {
			$Database.ExecuteNonQuery($Command, $Parameters)
		}
		else {
			$Database.Execute($Command, $Parameters)
		}
	}
}

#.ExternalHelp FarNet.SQLite-Help.xml
function Get-SQLite {
	[CmdletBinding(DefaultParameterSetName='Rows')]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[object]$Command
		,
		[Parameter(Position=1)]
		[ValidateNotNull()]
		[object[]]$Parameters = @()
		,
		[System.Data.SQLite.DB]$Database
		,
		[Parameter(ParameterSetName='Column', Mandatory=$true)]
		[switch]$Column
		,
		[Parameter(ParameterSetName='Lookup', Mandatory=$true)]
		[switch]$Lookup
		,
		[Parameter(ParameterSetName='Scalar', Mandatory=$true)]
		[switch]$Scalar
		,
		[Parameter(ParameterSetName='Table', Mandatory=$true)]
		[switch]$Table
	)

	if (!$Database -and !($Database = $PSCmdlet.GetVariableValue('db'))) {
		Write-Error 'Expected variable $db or parameter Database.'
	}

	if ($Command -is [System.Data.SQLite.SQLiteCommand]) {
		if ($Parameters) {
			Write-Error 'Parameters are not used with SQLiteCommand command.'
		}

		if ($Column) {
			$Database.ExecuteColumn($Command)
		}
		elseif ($Lookup) {
			$Database.ExecuteLookup($Command)
		}
		elseif ($Scalar) {
			$Database.ExecuteScalar($Command)
		}
		else {
			$r = $Database.ExecuteTable($Command)
			if ($Table) {, $r} else {$r}
		}
	}
	else {
		if ($Column) {
			$Database.ExecuteColumn($Command, $Parameters)
		}
		elseif ($Lookup) {
			$Database.ExecuteLookup($Command, $Parameters)
		}
		elseif ($Scalar) {
			$Database.ExecuteScalar($Command, $Parameters)
		}
		else {
			$r = $Database.ExecuteTable($Command, $Parameters)
			if ($Table) {, $r} else {$r}
		}
	}
}

#.ExternalHelp FarNet.SQLite-Help.xml
function New-SQLiteCommand {
	[CmdletBinding()]
	[OutputType([System.Data.SQLite.SQLiteCommand])]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[string]$Command
		,
		[Parameter(Position=1)]
		[System.Data.SQLite.SQLiteParameter[]]$Parameters
		,
		[switch]$Dispose
		,
		[System.Data.SQLite.DB]$Database
	)

	if (!$Database -and !($Database = $PSCmdlet.GetVariableValue('db'))) {
		Write-Error 'Expected variable $db or parameter Database.'
	}

	$Database.CreateCommand($Command, $Dispose, $Parameters)
}

#.ExternalHelp FarNet.SQLite-Help.xml
function New-SQLiteParameter {
	[CmdletBinding()]
	[OutputType([System.Data.SQLite.SQLiteParameter])]
	param(
		[Parameter(Mandatory=$true)]
		[string]$Name
		,
		[Parameter(Mandatory=$true)]
		[System.Data.DbType]$Type
		,
		[object]$Value
	)

	$r = [System.Data.SQLite.SQLiteParameter]::new($Name, $Type)
	if ($null -ne $Value) {
		$r.Value = $Value
	}
	$r
}
