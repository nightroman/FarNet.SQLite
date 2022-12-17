<#
	Use cases:
	- TransactionScope with two databases.
	- TransactionScope with new database.
	- $db(SQLiteConnection) nested transactions.
	- Use-SQLiteTransaction nested transactions.
#>

Set-StrictMode -Version 3
Import-Module FarNet.SQLite

# https://learn.microsoft.com/en-us/dotnet/api/system.transactions.transactionscope
task TransactionScopeWithTwoDatabases {
	$init = @'
create table t1 (name);
insert into t1 (name) values ("q1");
'@

	function Test-DB([switch]$Fail) {
		# init databases with 1 record
		remove z.*.db
		(1,2).foreach{
			Open-SQLite z.$_.db
			Set-SQLite $init
			Close-SQLite
		}

		# try adding 1 record to each
		$trans = [System.Transactions.TransactionScope]::new()
		try {
			(1,2).foreach{
				Open-SQLite z.$_.db
				Set-SQLite 'insert into t1 (name) values ("q2");'
				equals 2L (Get-SQLite -Scalar 'select count() from t1')
				Close-SQLite
			}

			# fail?
			if ($Fail) {
				throw 'KO'
			}

			# commit
			$trans.Complete()
			Write-Verbose -Verbose OK
		}
		catch {
			Write-Verbose -Verbose $_
		}
		finally {
			$trans.Dispose()
		}
	}

	# case OK: 2 records
	Test-DB
	(1,2).foreach{
		Open-SQLite z.$_.db
		equals 2L (Get-SQLite -Scalar 'select count() from t1')
		Close-SQLite
	}

	# case KO: 1 record
	Test-DB -Fail
	(1,2).foreach{
		Open-SQLite z.$_.db
		equals 1L (Get-SQLite -Scalar 'select count() from t1')
		Close-SQLite
	}

	remove z.*.db
}

# How TransactionScope works with new db.
task TransactionScopeCreateDatabaseAndRollback {
	$init = @'
create table t1 (name);
insert into t1 (name) values ("q1");
'@

	# ensure new db, mind z.db-journal
	remove z.db*

	# begin transaction
	$trans = [System.Transactions.TransactionScope]::new()

	# create db, add data, test, close
	Open-SQLite z.db
	Set-SQLite $init
	equals q1 (Get-SQLite -Column 'select name from t1')[0]
	Close-SQLite

	# these files are created
	equals (Get-Item z.db).Length 0L
	equals (Get-Item z.db-journal).Length 512L

	# rollback
	$trans.Dispose()

	# one empty file stays
	equals (Get-Item z.db).Length 0L
	assert (!(Test-Path z.db-journal))

	#!
	[GC]::Collect($true)
	[GC]::WaitForPendingFinalizers()
	remove z.db
}

# This test uses Use-SQLiteTransaction.
task NestedTransactions1 {
	Open-SQLite -AllowNestedTransactions

	Set-SQLite 'create table t1 (name)'

	Use-SQLiteTransaction {
		Set-SQLite 'insert into t1 (name) values ("q1")'

		Use-SQLiteTransaction {
			Set-SQLite 'insert into t1 (name) values ("q2")'
		}

		try {
			Use-SQLiteTransaction {
				Set-SQLite 'insert into t1 (name) values ("bad")'
				throw 'oops in nested'
			}
		}
		catch {}

		Use-SQLiteTransaction {
			Set-SQLite 'insert into t1 (name) values ("q3")'

			try {
				Use-SQLiteTransaction {
					Set-SQLite 'insert into t1 (name) values ("bad")'
					throw 'oops in nested'
				}
			}
			catch {}

			Set-SQLite 'insert into t1 (name) values ("q4")'
		}

		Set-SQLite 'insert into t1 (name) values ("q5")'
	}

	($r = Get-SQLite -Column 'select * from t1')
	equals ($r -join ',') 'q1,q2,q3,q4,q5'
}

# This test uses C# API (not designed for scripts).
task NestedTransactions2 {
	$db = [System.Data.SQLite.DB]::new(':memory:', 'Flags=AllowNestedTransactions')

	$db.Execute('create table t1 (name)')

	$db.UseTransaction({
		$db.Execute('insert into t1 (name) values ("q1")')

		$db.UseTransaction({
			$db.Execute('insert into t1 (name) values ("q2")')
		})

		try {
			$db.UseTransaction({
				$db.Execute('insert into t1 (name) values ("bad")')
				throw 'oops in nested'
			})
		}
		catch {}

		$db.UseTransaction({
			$db.Execute('insert into t1 (name) values ("q3")')

			try {
				$db.UseTransaction({
					$db.Execute('insert into t1 (name) values ("bad")')
					throw 'oops in nested'
				})
			}
			catch {}

			$db.Execute('insert into t1 (name) values ("q4")')
		})

		$db.Execute('insert into t1 (name) values ("q5")')
	})

	($r = $db.ExecuteColumn('select * from t1'))
	equals ($r -join ',') 'q1,q2,q3,q4,q5'
}

task BadComplete1 {
	Open-SQLite

	($r = try { Complete-SQLite } catch { $_ })
	assert "$r".Contains("There is no active transaction. It is either completed or not created.")

	Close-SQLite
}

task BadComplete2 {
	Open-SQLite -Transaction
	Complete-SQLite

	($r = try { Complete-SQLite } catch { $_ })
	assert "$r".Contains("There is no active transaction. It is either completed or not created.")

	Close-SQLite
}

# Error should point to the error line.
task TransactionError {
	Open-SQLite

	$r = try {
		Use-SQLiteTransaction {
			throw 'oops'
		}
	}
	catch {
		$_
	}

	equals "$r" oops
	equals $r.InvocationInfo.Line.Trim() "throw 'oops'"

	Close-SQLite
}

task TransactionOutput {
	Open-SQLite

	$r = Use-SQLiteTransaction {}
	equals $r $null

	$r = Use-SQLiteTransaction {42}
	equals $r 42

	$r = Use-SQLiteTransaction {42; 3.14}
	equals $r.GetType().Name 'Object[]'
	equals $r.Count 2
	equals $r[0] 42
	equals $r[1] 3.14

	Close-SQLite
}
