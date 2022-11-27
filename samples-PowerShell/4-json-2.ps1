# How to store and work with JSON.
# Just JSON and calculated fields.

$ErrorActionPreference=1
Import-Module FarNet.SQLite

Open-SQLite
Set-SQLite @'
create table t1 (
	Id as (value ->> '$.Id'),
	Name as (value ->> '$.Name'),
	WorkingSet as (value ->> '$.WorkingSet'),
	Value
);
create index t1_Id on t1(Id);
create index t1_Name on t1(Name);
'@

# get and insert data with a json field
$data = Get-Process conhost*, far*
foreach($_ in $data) {
	$db.Execute('insert into t1 (Value) values (@Value)', @{
		Value = $_ | Select-Object Id, Name, WorkingSet, Handles | ConvertTo-Json -Compress
	})
}

# show Id, Name, WorkingSet
Get-SQLite 'select Id, Name, WorkingSet from t1' | Out-String

# get average WorkingSet
$avg = Get-SQLite -Scalar 'select avg(WorkingSet) from t1'

# get filtered data
Get-SQLite 'select Id, Name, WorkingSet from t1 where WorkingSet > @avg' @{avg = $avg} | Out-String

Close-SQLite
