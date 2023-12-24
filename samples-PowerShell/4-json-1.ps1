# How to store and work with JSON.
# Some normal fields and one JSON.

$ErrorActionPreference=1
Import-Module FarNet.SQLite

Open-SQLite
Set-SQLite @'
create table t1 (
	Id,
	Name,
	Value
);
create index t1_Id on t1(Id);
create index t1_Name on t1(Name);
'@

# get and insert data with a json field
$data = Get-Process conhost*, far*
foreach($_ in $data) {
	Set-SQLite 'insert into t1 (Id, Name, Value) values (@Id, @Name, @Value)' @{
		Id = $_.Id
		Name = $_.Name
		Value = $_ | Select-Object WorkingSet, Handles | ConvertTo-Json -Compress
	}
}

# show Id, Name, WorkingSet
Get-SQLite 'select Id, Name, Value ->> "$.WorkingSet" as WorkingSet from t1' | Out-String

# get average WorkingSet
$avg = Get-SQLite -Scalar 'select avg(Value ->> "$.WorkingSet") from t1'

# get filtered data
Get-SQLite 'select Id, Name, Value ->> "$.WorkingSet" as WorkingSet from t1 where Value ->> "$.WorkingSet" > @avg' @{avg = $avg} | Out-String

Close-SQLite
