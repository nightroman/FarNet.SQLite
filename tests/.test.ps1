
Set-StrictMode -Version 3
Import-Module FarNet.SQLite

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
	equals $db.Connection.ConnectionString 'flags="AllowNestedTransactions, Default";foreignkeys=True;readonly=True;data source=:memory:'
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
	assert "$r".Contains('UNIQUE constraint failed: t1.id"')
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
