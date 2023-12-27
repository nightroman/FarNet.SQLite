
Set-StrictMode -Version 3
Import-Module FarNet.SQLite

$_Database = @'
		The database from `Open-SQLite`, the variable `$db` by default.
'@

$_Command = @'
		Specifies the command, either text or `SQLiteCommand`.
'@

$_Parameters = @'
		When Command is text, specifies command parameters: `IDictionary` or
		`SQLiteParameter` for named parameters or objects for positional
		parameters.
'@

### Close-SQLite
@{
	command = 'Close-SQLite'
	synopsis = 'Closes the SQLite database connection.'
	description = 'This command closes the database opened by `Open-SQLite`.'
	parameters = @{
		Database = $_Database
	}
}

### Complete-SQLite
@{
	command = 'Complete-SQLite'
	synopsis = 'Completes the transaction created on opening.'
	description = @'
	It completes the transaction created by `Open-SQLite -Transaction`. This
	command should be called once before `Close-SQLite`. If it is not called
	then `Close-SQLite` discards all changes.
'@
	parameters = @{
		Database = $_Database
	}
}

### Get-SQLite
@{
	command = 'Get-SQLite'
	synopsis = 'Invokes the query command.'
	description = @'
	This command invokes query commands like SELECT. It returns `DataRow`
	objects by default. Use `Scalar`, `Column`, `Lookup`, `Table` for
	different results, depending on the query.

	DBNull values are converted to nulls with Scalar, Column, Lookup.
'@
	parameters = @{
		Command = $_Command
		Parameters = $_Parameters
		Column = 'Tells to return an array of the first column values. DBNull values are converted to nulls.'
		Lookup = 'Tells to return a dictionary of the first two columns. DBNull values are converted to nulls.'
		Scalar = 'Tells to return the first result value. DBNull values are converted to nulls.'
		Table = 'Tells to return the result as DataTable.'
		Database = $_Database
	}
	outputs = @(
		@{
			type = 'DataRow'
			description = 'The default.'
		}
		@{
			type = 'DataTable'
			description = 'When -Table.'
		}
		@{
			type = 'Object'
			description = 'When -Scalar.'
		}
		@{
			type = 'Object[]'
			description = 'When -Column.'
		}
		@{
			type = 'Dictionary'
			description = 'When -Lookup.'
		}
	)
}

### New-SQLiteCommand
@{
	command = 'New-SQLiteCommand'
	synopsis = 'Creates a command with some options.'
	description = @'
	Use this command to create prepared commands and parameters. Prepared
	commands and parameters work faster on repeated calls, i.e. in loops.

	For single calls use unprepared text commands with simple parameters.
	Performance is the same but the code is easier to compose and read.
'@
	parameters = @{
		Command = 'Specifies the command text.'
		Parameters = @'
		Specifies command `SQLiteParameter` parameters.
		Use `New-SQLiteParameter` to create parameters.
'@
		Dispose = 'Tells to dispose the command on closing.'
		Database = $_Database
	}
	outputs = @(
		@{
			type = 'SQLiteCommand'
			description = 'The created command.'
		}
	)
}

### New-SQLiteParameter
@{
	command = 'New-SQLiteParameter'
	synopsis = 'Creates SQLiteParameter.'
	description = @'
	Use this command to create prepared parameters. These parameters are used
	with prepared commands in order to improve performance on repeated calls.

	Prepared parameters are usually created once and added to one or more
	prepared commands. Then parameter values are updated before executing.
'@
	parameters = @{
		Name = 'Specifies the parameter name.'
		Type = 'Specifies the parameter type.'
		Value = 'Optional parameter value.'
	}
	outputs = @{
		type = 'SQLiteParameter'
		description = 'The created parameter.'
	}
}

### Open-SQLite
@{
	command = 'Open-SQLite'
	synopsis = 'Opens SQLite database connection.'
	description = @'
	This command opens the connection and creates the database variable in the
	calling scope, `$db` by default. Then other commands use the variable `$db`
	as the default value of their parameter `Database`.

	If `Database` and `Options` are both omitted or empty then ":memory:" is used.
	Otherwise one of these parameters should specify the database.

	Use `$db.Connection` in order to get the underlying `SQLiteConnection`.

	When the work is done, close the database by `Close-SQLite`.
'@
	parameters = @{
		Database = @'
		Specifies the database file or ":memory:". If it is empty and `Options`
		is not empty then `Options` must provide "Data Source".
'@
		Options = @'
		Connection string extra options or the full connection string.
'@
		CreateFile = @'
		Tells to create a new file before opening the connection.
		This switch is used when Database is specified.
'@
		Transaction = @'
		Tells to begin a transaction after opening the connection.
		Commit the transaction by `Complete-SQLite` before `Close-SQLite`.
'@
		AllowNestedTransactions = 'Adds `AllowNestedTransactions` to `Flags`.'
		ForeignKeys = 'Sets the option `Foreign Keys`.'
		ReadOnly = 'Sets the option `Read Only`.'
		Variable = @'
		Specifies the database variable name. The default and recommended is `db`.
		Other names are only needed for using several databases at the same time.
'@
	}
	outputs = @{
		type = 'None'
		description = 'The result is a variable set in the calling scope ($db).'
	}
}

### Set-SQLite
@{
	command = 'Set-SQLite'
	synopsis = 'Invokes the non-query command.'
	description = @'
	This command invokes non-query commands, e.g. CREATE, INSERT, DELETE, etc.
	It returns nothing by default. Use Result in order to get the result number.
'@
	parameters = @{
		Command = $_Command
		Parameters = $_Parameters
		Result = 'Tells to return the affected records count.'
		Database = $_Database
	}
	outputs = @(
		@{
			type = 'None'
			description = 'The default.'
		}
		@{
			type = 'Int32'
			description = 'With -Result, the affected records count.'
		}
	)
}

### Register-SQLiteFunction
@{
	command = 'Register-SQLiteFunction'
	synopsis = 'Registers script blocks as SQLite functions.'
	description = @'
	This command registers the specified script as SQLite function.
	Script and function argument count is specified by Arguments.

	If any SQLite argument is null then the function returns null and the
	script is not called. If the script fails then the function returns null.
'@
	parameters = @{
		Name = 'The SQLite function name.'
		Arguments = 'The function and script argument count.'
		Script = 'The script registered as the SQLite function.'
		Database = $_Database
	}
}

### Use-SQLiteTransaction
@{
	command = 'Use-SQLiteTransaction'
	synopsis = 'Invokes script using a transaction.'
	description = @'
	This command begins a new transaction and invokes the specified script.
	If the script completes without terminating errors the transaction commits.

	Consider using `Open-SQLite -Transaction` and `Complete-SQLite` instead.

	Open the database with `AllowNestedTransactions` for nested transactions.
'@
	parameters = @{
		Script = 'The script invoked using a new transaction.'
		Database = $_Database
	}
	outputs = @{
		type = 'None, Object, Object[]'
		description = 'Output of the invoked script.'
	}
}
