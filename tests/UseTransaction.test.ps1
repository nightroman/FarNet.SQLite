
Add-Type -Path $env:FARHOME\FarNet\Lib\FarNet.SQLite\FarNet.SQLite.dll

task Nested {
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

	$r = $db.ExecuteTable('select * from t1')
	$r | Out-String

	equals ($r.foreach{$_.name} -join ',') 'q1,q2,q3,q4,q5'
}
