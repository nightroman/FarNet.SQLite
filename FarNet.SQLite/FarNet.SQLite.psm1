$ErrorActionPreference=1

<#
.Synopsis
	Opens SQLite database connection.

.Description
	This command opens the connection and creates the database variable in the
	calling scope, `$db` by default. Then other commands use the variable `$db`
	as the default value of their parameter `Database`.

	If `Database` and `Options` are both omitted or empty then ":memory:" is used.
	Otherwise one of these parameters should specify the database.

	Use `$db.Connection` in order to get the underlying `SQLiteConnection`.

	When the work is done, close the database by `Close-SQLite`.

.Parameter Database
		Specifies the database file or ":memory:". If it is empty and `Options`
		is not empty then `Options` must provide "Data Source".

.Parameter Options
		Connection string extra options or the full connection string.

.Parameter CreateFile
		Tells to create a new file before opening the connection.
		This switch is used when Database is specified.

.Parameter Transaction
		Tells to begin a transaction after opening the connection.
		Commit the transaction by `Complete-SQLite` before `Close-SQLite`.

.Parameter AllowNestedTransactions
		Adds `AllowNestedTransactions` to `Flags`.

.Parameter ForeignKeys
		Sets the option `Foreign Keys`.

.Parameter ReadOnly
		Sets the option `Read Only`.

.Parameter Variable
		Specifies the database variable name. The default and recommended is `db`.
		Other names are only needed for using several databases at the same time.

.Outputs
	No output, the result is a variable set in the calling scope ($db).
#>
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

<#
.Synopsis
	Closes the SQLite database connection.

.Description
	This command closes the database opened by `Open-SQLite`.

.Parameter Database
		The database from `Open-SQLite`, the variable $db by default.
#>
function Close-SQLite {
	[CmdletBinding()]
	param(
		[Parameter(Position=0)]
		[System.Data.SQLite.DB]$Database
	)

	if (!$Database) {
		if (!($Database = $PSCmdlet.GetVariableValue('db'))) {
			Write-Error 'Expected variable $db or parameter Database.'
		}
	}

	$Database.Dispose()
}

<#
.Synopsis
	Completes the transaction created on opening.

.Description
	It completes the transaction created by `Open-SQLite -Transaction`. This
	command should be called once before `Close-SQLite`. If it is not called
	then `Close-SQLite` discards all changes.

.Parameter Database
		The database from `Open-SQLite`, the variable $db by default.
#>
function Complete-SQLite {
	[CmdletBinding()]
	param(
		[Parameter(Position=0)]
		[System.Data.SQLite.DB]$Database
	)

	if (!$Database) {
		if (!($Database = $PSCmdlet.GetVariableValue('db'))) {
			Write-Error 'Expected variable $db or parameter Database.'
		}
	}

	$Database.Commit()
}

<#
.Synopsis
	Invokes the non-query command.

.Description
	This command invokes non-query commands, e.g. CREATE, INSERT, DELETE, etc.
	It returns nothing by default. Use Result in order to get the result number.

.Parameter Command
		Specifies the non-query command.

.Parameter Parameters
		Command parameters: `IDictionary` or `SQLiteParameter` for named parameters or objects for positional parameters.

.Parameter Result
		Tells to return the affected records count.

.Parameter Database
		The database from `Open-SQLite`, the variable $db by default.

.Outputs
	None or integer.
#>
function Set-SQLite {
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[string]$Command
		,
		[Parameter(Position=1)]
		[object[]]$Parameters = @()
		,
		[switch]$Result
		,
		[System.Data.SQLite.DB]$Database
	)

	if (!$Database) {
		if (!($Database = $PSCmdlet.GetVariableValue('db'))) {
			Write-Error 'Expected variable $db or parameter Database.'
		}
	}

	if ($Result) {
		$Database.ExecuteNonQuery($Command, $Parameters)
	}
	else {
		$Database.Execute($Command, $Parameters)
	}
}

<#
.Synopsis
	Invokes the query command.

.Description
	This command invokes query commands like SELECT. It returns `DataRow`
	objects by default. Use `Scalar`, `Column`, `Lookup`, `Table` for
	different results, depending on the query.

.Parameter Command
		Specifies the query command.

.Parameter Parameters
		Command parameters: `IDictionary` or `SQLiteParameter` for named parameters or objects for positional parameters.

.Parameter Column
		Tells to return the first column values array.

.Parameter Lookup
		Tells to return the first two columns dictionary.

.Parameter Scalar
		Tells to return the first result value.

.Parameter Table
		Tells to return the result as DataTable.

.Parameter Database
		The database from `Open-SQLite`, the variable $db by default.

.Outputs
	DataRow, DataTable, Dictionary, object.
#>
function Get-SQLite {
	[CmdletBinding(DefaultParameterSetName='Rows')]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[string]$Command
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

	if (!$Database) {
		if (!($Database = $PSCmdlet.GetVariableValue('db'))) {
			Write-Error 'Expected variable $db or parameter Database.'
		}
	}

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
