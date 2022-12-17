
Set-StrictMode -Version 3
Import-Module FarNet.SQLite
$Version = $PSVersionTable.PSVersion.Major

task BasicDefaultVariable {
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

task BasicCustomVariable {
	Open-SQLite -Variable database

	$r = Set-SQLite 'create table t1 (Name)' -Database $database
	equals $r $null

	$r = Set-SQLite 'insert into t1 (Name) values ("_221126_0256")' -Result -Database $database
	equals $r 1

	$r = Get-SQLite 'select Name from t1' -Scalar -Database $database
	equals $r _221126_0256

	$r = Get-SQLite 'select Name from t1' -Table -Database $database
	assert ($r -is [System.Data.DataTable])
	equals $r[0].Name _221126_0256

	$r = Get-SQLite 'select Name from t1' -Database $database
	assert ($r -is [System.Data.DataRow])
	equals $r.Name _221126_0256

	Close-SQLite -Database $database
}

task OpenParameters {
	Open-SQLite
	equals $db.Connection.ConnectionString 'data source=:memory:'
	Close-SQLite

	Open-SQLite -AllowNestedTransactions -ForeignKeys -ReadOnly
	equals $db.Connection.ConnectionString 'flags="AllowNestedTransactions, Default";foreign keys=True;read only=True;data source=:memory:'
	Close-SQLite
}

task Memory {
	#! fixed
	Open-SQLite :memory:
}

# SQLite is case sensitive by default
task CaseSensitive {
	Open-SQLite :memory:
	Set-SQLite @'
create table t1 (id string primary key);
insert into t1 (id) values ("q1");
insert into t1 (id) values ("Q1");
'@
	equals q1 (Get-SQLite -Scalar 'select id from t1 where id="q1"')
	equals Q1 (Get-SQLite -Scalar 'select id from t1 where id="Q1"')
	equals 'Q1,q1' ((Get-SQLite -Column 'select distinct id from t1') -join ',')
	Close-SQLite
}

# Use `collate nocase` to ignore case.
task CaseInsensitive {
	Open-SQLite :memory:
	Set-SQLite @'
create table t1 (id string collate nocase primary key);
insert into t1 (id) values ("q1");
'@
	($r = try { Set-SQLite 'insert into t1 (id) values ("Q1");' } catch { $_ })
	assert "$r".Contains('UNIQUE constraint failed: t1.id')
	Close-SQLite
}

# It's fine to close twice.
task DoubleClose {
	Open-SQLite
	Close-SQLite
	Close-SQLite
}

#! Fixed.
task NullPositionalParameters {
	Open-SQLite
	Set-SQLite 'create table t1 (id, name)'
	Set-SQLite 'insert into t1 (id, name) values (42, ?);' $null
	Set-SQLite 'insert into t1 (id, name) values (?1, ?2);' $null, $null
	$1, $2 = Get-SQLite 'select rowid, id, name from t1'
	equals $1.rowid 1L
	equals $1.id 42L
	equals $1.name ([DBNull]::Value)
	equals $2.rowid 2L
	equals $2.id ([DBNull]::Value)
	equals $2.name ([DBNull]::Value)
	Close-SQLite
}

task WhyNewSQLiteParameter {
	# these parameters look the same
	$p1 = New-SQLiteParameter Time DateTime
	$p2 = [System.Data.SQLite.SQLiteParameter]::new('Time', [datetime])

	# but they are not
	equals $p1.DbType ([System.Data.DbType]::DateTime)
	equals $p2.DbType ([System.Data.DbType]::String)
}

task GetColumnShouldReturnArray {
	Open-SQLite
	Set-SQLite 'create table t1 (Name)'

	$r = Get-SQLite -Column 'select Name from t1'
	equals $r.GetType().Name 'Object[]'
	equals $r.Length 0

	Set-SQLite 'insert into t1 (name) values ("q1")'

	$r = Get-SQLite -Column 'select Name from t1'
	equals $r.GetType().Name 'Object[]'
	equals $r.Length 1

	$cmd = New-SQLiteCommand 'select Name from t1'
	$r = Get-SQLite -Column $cmd
	equals $r.GetType().Name 'Object[]'
	equals $r.Length 1

	Close-SQLite
}

task Regexp {
	Open-SQLite

	# works as operator
	$r = Get-SQLite -Scalar 'SELECT "йцукен" REGEXP "^.*цук.*$"'
	equals $r 1L

	# works as function
	$r = Get-SQLite -Scalar 'SELECT REGEXP("^.*цук.*$", "йцукен")'
	equals $r 1L

	# it is case sensitive
	$r = Get-SQLite -Scalar 'SELECT "йцукен" REGEXP "^.*ЦУК.*$"'
	equals $r 0L

	# how to make it case insensitive
	$r = Get-SQLite -Scalar 'SELECT "йцукен" REGEXP "(?i)^.*ЦУК.*$"'
	equals $r 1L

	# any argument not string -> false
	$r = Get-SQLite -Scalar 'SELECT 1 REGEXP "1"'
	equals $r 0L
	$r = Get-SQLite -Scalar 'SELECT "1" REGEXP 1'
	equals $r 0L

	Close-SQLite
}

task BindFunction1 {
	Open-SQLite
	$db.BindScalarFunction('ToUpper', 1, {$args[0][0].ToUpper()})
	$db.BindScalarFunction('TestNull', 1, {throw '_221213_0843'})

	# works
	$r = Get-SQLite -Scalar 'SELECT ToUpper("йцукен")'
	equals $r ЙЦУКЕН

	# exception -> null, exception "swallowed"
	$r = Get-SQLite -Scalar 'SELECT TestNull("йцукен")'
	equals $r ([DBNull]::Value)
	equals "$($Error[0])" _221213_0843
	$Error.Clear()

	# null is passed -> function is not called
	$r = Get-SQLite -Scalar 'SELECT TestNull(null)'
	equals $r ([DBNull]::Value)
	equals $Error.Count 0

	Close-SQLite
}

task BindFunction2 {
	Open-SQLite
	$db.BindScalarFunction('Add2', 2, {$args[0][0] + $args[0][1]})
	$db.BindScalarFunction('TestNull', 2, {throw '_221213_0843'})

	# works
	$r = Get-SQLite -Scalar 'SELECT Add2("йцукен", "qwerty")'
	equals $r йцукенqwerty

	# works, but...
	$r = Get-SQLite -Scalar 'SELECT Add2(42, 3.14)'
	if ($Version -ge 7) {
		equals $r 45.14 #! double
	}
	else {
		equals $r '45.14' #! string, PSObject converted to string by SQLite
	}

	# exception -> null, exception "swallowed"
	$r = Get-SQLite -Scalar 'SELECT TestNull("1", "2")'
	equals $r ([DBNull]::Value)
	equals "$($Error[0])" _221213_0843
	$Error.Clear()

	# null is passed as arg 1 -> function is not called
	$r = Get-SQLite -Scalar 'SELECT TestNull(null, "2")'
	equals $r ([DBNull]::Value)
	equals $Error.Count 0

	# null is passed as arg 2 -> function is not called
	$r = Get-SQLite -Scalar 'SELECT TestNull("1", null)'
	equals $r ([DBNull]::Value)
	equals $Error.Count 0

	Close-SQLite
}

task RegisterFunction {
	Open-SQLite
	Register-SQLiteFunction MySq 1 {$args[0] * $args[0]}
	Register-SQLiteFunction Add2 2 {$args[0] + $args[1]}

	$r = Get-SQLite -Scalar 'SELECT MySq(42)'
	equals $r 1764L

	$r = Get-SQLite -Scalar 'SELECT Add2(42, 3.14)'
	equals $r 45.14

	$r = Get-SQLite -Scalar 'SELECT Add2("йцукен", "qwerty")'
	equals $r йцукенqwerty

	Close-SQLite
}

task Help {
	(Get-Command -Module FarNet.SQLite).ForEach{
		Write-Host $_.Name
		$r = Get-Help $_
		assert ($r.Synopsis.EndsWith('.')) 'Missing or unexpected Synopsis?'
		assert ($r.Description.Count -ge 1) 'Missing or unexpected Description?'
	}
}
