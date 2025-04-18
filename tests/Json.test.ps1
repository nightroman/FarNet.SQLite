#requires -Modules FarNet.SQLite
Set-StrictMode -Version 3

function get_json($Path, $Json) {
	Get-SQLite -Scalar 'select @1 -> @2' $Json, $Path
}

function get_json2($Path, $Json) {
	Get-SQLite -Scalar 'select @1 ->> @2' $Json, $Path
}

function get_jsonExtract($Path, $Json) {
	Get-SQLite -Scalar 'select json_extract(@1, @2)' $Json, $Path
}

task Json {
	Open-SQLite

	# array item by index, shortcut
	($r = get_json 3 '[11,22,33,44]')
	equals $r '44'
	($r = get_json2 3 '[11,22,33,44]')
	equals $r 44L
	($r = try {get_jsonExtract 3 '[11,22,33,44]'} catch {$_})
	equals "$r" "SQL logic error`r`nbad JSON path: '3'"

	# array item by index, normal
	($r = get_json $[3] '[11,22,33,44]')
	equals $r '44'
	($r = get_json2 $[3] '[11,22,33,44]')
	equals $r 44L
	($r = get_jsonExtract $[3] '[11,22,33,44]')
	equals $r 44L

	# get element null
	($r = get_json $.a '{"a":null}')
	equals $r 'null'
	($r = get_json2 $.a '{"a":null}')
	equals $r $null
	($r = get_jsonExtract $.a '{"a":null}')
	equals $r $null

	# get element scalar
	($r = get_json $.a '{"a":"xyz"}')
	equals $r '"xyz"'
	($r = get_json2 $.a '{"a":"xyz"}')
	equals $r 'xyz'
	($r = get_jsonExtract $.a '{"a":"xyz"}')
	equals $r 'xyz'

	# get element array, all the same
	($r = get_json $.a '{"a":["xyz"]}')
	equals $r '["xyz"]'
	($r = get_json2 $.a '{"a":["xyz"]}')
	equals $r '["xyz"]'
	($r = get_jsonExtract $.a '{"a":["xyz"]}')
	equals $r '["xyz"]'

	# get element object, all the same
	($r = get_json $.a '{"a":{b:"xyz"}}')
	equals $r '{"b":"xyz"}'
	($r = get_json2 $.a '{"a":{b:"xyz"}}')
	equals $r '{"b":"xyz"}'
	($r = get_jsonExtract $.a '{"a":{b:"xyz"}}')
	equals $r '{"b":"xyz"}'

	Close-SQLite
}
