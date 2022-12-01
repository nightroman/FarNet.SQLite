# How to use GetSchema() and GetSchema(name).

[CmdletBinding()]
param(
	[string]$Database = "$env:FARLOCALPROFILE\history.db"
)

Open-SQLite $Database -ReadOnly

# get all schema tables by GetSchema()
$collections = $db.Connection.GetSchema()

# get and show details by GetSchema(name)
foreach($collection in $collections) {
	$collection.CollectionName.PadRight($Host.UI.RawUI.WindowSize.Width - 2, '-')
	$dt = $db.Connection.GetSchema($collection.CollectionName)
	if ($dt.Rows.Count -eq 1) {
		$dt | Format-List | Out-String
	}
	else {
		$dt | Format-Table | Out-String
	}
}

Close-SQLite
