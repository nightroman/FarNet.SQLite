<#
.Synopsis
	How to use DataFrame with SQLite.
#>

#requires -Modules DataFrame, FarNet.SQLite
$ErrorActionPreference = 1

Open-SQLite
Set-SQLite 'create table t1 (Id, Name, WorkingSet)'

Get-Process conhost*, far* | .{process{
	Set-SQLite 'insert into t1 (Id, Name, WorkingSet) values (@1, @2, @3)' $_.Id, $_.Name, $_.WorkingSet
}}

$cmd = New-SQLiteCommand -Dispose 'select Id, Name, WorkingSet from t1'
$df = Read-DataFrame ($cmd.ExecuteReader())
$df.ToTable()

Close-SQLite
