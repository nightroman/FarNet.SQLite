# Performance tips:
# - use transactions on making multiple changes
# - use prepared commands and parameters in loops

$N = 200
$ErrorActionPreference=1
Import-Module FarNet.SQLite

### Slow (no transaction, simple commands and parameters)

$sw = [System.Diagnostics.Stopwatch]::StartNew()
Open-SQLite z.db -CreateFile
try {
	# make schema
	Set-SQLite 'CREATE TABLE MyTable (MyId INTEGER PRIMARY KEY)'

	# call INSERT $N times
	1..$N | .{process{
		Set-SQLite "INSERT INTO MyTable (MyId) VALUES (@MyId)" @{MyId = $_}
	}}
}
finally {
	Close-SQLite
}
$sw.Elapsed.ToString()

### Fast (transaction, prepared commands and parameters)

$sw = [System.Diagnostics.Stopwatch]::StartNew()
Open-SQLite z.db -CreateFile -Transaction
try {
	# this command is used once, simple is fine
	Set-SQLite 'CREATE TABLE MyTable (MyId INTEGER PRIMARY KEY)'

	# prepare the parameter and command
	$MyId = New-SQLiteParameter MyId Int64
	$cmd = New-SQLiteCommand -Dispose 'INSERT INTO MyTable (MyId) VALUES (@MyId)' $MyId

	# update the parameter and run the prepared command
	1..$N | .{process{
		$MyId.Value = $_
		Set-SQLite $cmd
	}}

	# commit work
	Complete-SQLite
}
finally {
	Close-SQLite
}
$sw.Elapsed.ToString()

Remove-Item z.db
