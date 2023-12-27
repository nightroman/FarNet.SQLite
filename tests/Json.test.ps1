#requires -Modules FarNet.SQLite
Set-StrictMode -Version 3

function Get-SQLiteJson($Path, $Json) {
	Get-SQLite -Scalar 'select @1 -> @2' $Json, $Path
}

function Get-SQLiteJson2($Path, $Json) {
	Get-SQLite -Scalar 'select @1 ->> @2' $Json, $Path
}

function Get-SQLiteJsonExtract($Path, $Json) {
	Get-SQLite -Scalar 'select json_extract(@1, @2)' $Json, $Path
}

task Json {
	Open-SQLite

	# array item by index, shortcut
	($r = Get-SQLiteJson 3 '[11,22,33,44]')
	equals $r '44'
	($r = Get-SQLiteJson2 3 '[11,22,33,44]')
	equals $r 44L
	($r = try {Get-SQLiteJsonExtract 3 '[11,22,33,44]'} catch {$_})
	assert ("$r" -like "*JSON path error near '3'")

	# array item by index, normal
	($r = Get-SQLiteJson $[3] '[11,22,33,44]')
	equals $r '44'
	($r = Get-SQLiteJson2 $[3] '[11,22,33,44]')
	equals $r 44L
	($r = Get-SQLiteJsonExtract $[3] '[11,22,33,44]')
	equals $r 44L

	# get element null
	($r = Get-SQLiteJson $.a '{"a":null}')
	equals $r 'null'
	($r = Get-SQLiteJson2 $.a '{"a":null}')
	equals $r $null
	($r = Get-SQLiteJsonExtract $.a '{"a":null}')
	equals $r $null

	# get element scalar
	($r = Get-SQLiteJson $.a '{"a":"xyz"}')
	equals $r '"xyz"'
	($r = Get-SQLiteJson2 $.a '{"a":"xyz"}')
	equals $r 'xyz'
	($r = Get-SQLiteJsonExtract $.a '{"a":"xyz"}')
	equals $r 'xyz'

	# get element array, all the same
	($r = Get-SQLiteJson $.a '{"a":["xyz"]}')
	equals $r '["xyz"]'
	($r = Get-SQLiteJson2 $.a '{"a":["xyz"]}')
	equals $r '["xyz"]'
	($r = Get-SQLiteJsonExtract $.a '{"a":["xyz"]}')
	equals $r '["xyz"]'

	# get element object, all the same
	($r = Get-SQLiteJson $.a '{"a":{b:"xyz"}}')
	equals $r '{"b":"xyz"}'
	($r = Get-SQLiteJson2 $.a '{"a":{b:"xyz"}}')
	equals $r '{"b":"xyz"}'
	($r = Get-SQLiteJsonExtract $.a '{"a":{b:"xyz"}}')
	equals $r '{"b":"xyz"}'

	Close-SQLite
}
