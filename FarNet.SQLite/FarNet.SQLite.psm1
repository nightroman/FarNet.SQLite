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

	Use `$db.Connection` in order to access the underlying `SQLiteConnection`.

.Parameter Database
		Specifies the database file or ":memory:". If it is empty and `Options`
		is not empty then `Options` must provide "Data Source".

.Parameter Options
		Connection string extra options or the full connection string.

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

	$db = [System.Data.SQLite.DB]::new($Database, $sb.ConnectionString)
	$PSCmdlet.SessionState.PSVariable.Set($Variable, $db)
}

<#
.Synopsis
	Closes the SQLite database connection.

.Description
	Databases opened by `Open-SQLite` must be closed by `Close-SQLite`.

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
	Invokes non-query SQLite commands.

.Description
	This command invokes non-query commands, e.g. CREATE, INSERT, DELETE, etc.
	It returns nothing by default. Use Result in order to get the result number.

.Parameter Command
		Specifies the non-query SQLite command.

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
	Invokes SQLite query commands.

.Description
	This command invokes query commands like SELECT. It returns `DataRow`
	objects by default. Use `Scalar` or `Table` to alter the result type.

.Parameter Command
		Specifies the non-query SQLite command.

.Parameter Parameters
		Command parameters: `IDictionary` or `SQLiteParameter` for named parameters or objects for positional parameters.

.Parameter Scalar
		Tells to return the first result value.

.Parameter Table
		Tells to return DataTable as the result.

.Parameter Database
		The database from `Open-SQLite`, the variable $db by default.

.Outputs
	DataRow, DataTable, object.
#>
function Get-SQLite {
	[CmdletBinding()]
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
		[switch]$Scalar
		,
		[switch]$Table
	)

	if (!$Database) {
		if (!($Database = $PSCmdlet.GetVariableValue('db'))) {
			Write-Error 'Expected variable $db or parameter Database.'
		}
	}

	if ($Scalar) {
		$Database.ExecuteScalar($Command, $Parameters)
	}
	else {
		$r = $Database.ExecuteTable($Command, $Parameters)
		if ($Table) {, $r} else {$r}
	}
}

<#
.Synopsis
	Invokes script with transaction.

.Description
	This command begins a new transaction and invokes the specified script.
	If the script completes without terminating errors the transaction commits.

	Open the database with `AllowNestedTransactions` for nested transactions.

.Parameter Script
		The script invoked with a new transaction.

.Parameter Database
		The database from `Open-SQLite`, the variable $db by default.

.Outputs
	None or objects returned by the script.
#>
function Use-SQLiteTransaction {
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[scriptblock]$Script
		,
		[System.Data.SQLite.DB]$Database
	)

	if (!$Database) {
		if (!($Database = $PSCmdlet.GetVariableValue('db'))) {
			Write-Error 'Expected variable $db or parameter Database.'
		}
	}

	$transaction = $Database.Connection.BeginTransaction()
	try {
		& $Script
		$transaction.Commit()
	}
	finally {
		$transaction.Dispose()
	}
}
