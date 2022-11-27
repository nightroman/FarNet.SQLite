
Set-StrictMode -Version 3
Import-Module FarNet.SQLite

task Basic {
	Open-SQLite

	$r = Set-SQLite 'create table t1 (Name)'
	equals $r $null

	$r = Set-SQLite 'insert into t1 (Name) values ("_221126_0256")' -Result
	equals $r 1

	$r = Get-SQLite 'select Name from t1' -Scalar
	equals $r _221126_0256

	$r = Get-SQLite 'select Name from t1' -Table
	assert ($r -is [System.Data.DataTable])
	equals $r[0].Name _221126_0256

	$r = Get-SQLite 'select Name from t1'
	assert ($r -is [System.Data.DataRow])
	equals $r.Name _221126_0256

	Close-SQLite
}

task Transaction {
	Open-SQLite
	Set-SQLite 'create table t1 (Name)'

	$_221126_0332 = '_221126_0332'
	Use-SQLiteTransaction {
		Set-SQLite 'insert into t1 (Name) values (@Name)' @{Name = $_221126_0332}
	}

	$r = Get-SQLite 'select Name from t1'
	equals $r.Name _221126_0332

	$r = $(
		try {
			Use-SQLiteTransaction {
				throw <##> 42
			}
		}
		catch {
			$_
		}
	)

	equals "$r" '42'
	assert $r.InvocationInfo.Line.Contains('throw <##> 42')

	Close-SQLite
}

task OpenParameters {
	Open-SQLite
	equals $db.Connection.ConnectionString 'data source=:memory:'
	Close-SQLite

	Open-SQLite -AllowNestedTransactions -ForeignKeys -ReadOnly
	equals $db.Connection.ConnectionString 'flags="AllowNestedTransactions, Default";foreignkeys=True;readonly=True;data source=:memory:'
	Close-SQLite
}

task Memory {
	#! fixed
	Open-SQLite :memory:
}
