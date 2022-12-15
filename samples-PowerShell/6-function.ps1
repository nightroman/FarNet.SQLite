# Example of SQLite script function

$ErrorActionPreference=1
Import-Module FarNet.SQLite

Open-SQLite

# create a table with two colums with some data
Set-SQLite <#sql#>@'
create table t1 (data1, data2);
insert into t1 (data1, data2) values (42, 3.14);
insert into t1 (data1, data2) values ("Foo", "Bar");
'@

# function `Plus` applies `+` to any two arguments
Register-SQLiteFunction Plus 2 {$args[0] + $args[1]}

# get (data1 + data2) ~ 45.14 and "FooBar"
Get-SQLite -Column 'select Plus(data1, data2) from t1'

Close-SQLite
