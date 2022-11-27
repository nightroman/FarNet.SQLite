# This sample uses System.Data.SQLite without helpers.

$ErrorActionPreference=1
Add-Type -Path $env:FARHOME\FarNet\Lib\FarNet.SQLite\System.Data.SQLite.dll

$db = [System.Data.SQLite.SQLiteConnection]::new()
$db.ConnectionString = "data source=:memory:"
$db.Open()

$cmd = $db.CreateCommand()
$cmd.CommandText = <#sql#>@'
CREATE TABLE [TestCategories]
(
    [CategoryId] INTEGER PRIMARY KEY,
    [Category] TEXT NOT NULL,
    [Remarks] TEXT NULL
);
INSERT INTO TestCategories (Category, Remarks) VALUES ('Task', 'Task remarks');
INSERT INTO TestCategories (Category, Remarks) VALUES ('Warning', 'Warning remarks');
'@
$null = $cmd.ExecuteNonQuery()
$cmd.Dispose()

$table = [System.Data.DataTable]::new()
$cmd = $db.CreateCommand()
$cmd.CommandText = "SELECT * FROM TestCategories"
$adapter = [System.Data.SQLite.SQLiteDataAdapter]::new($cmd)
$null = $adapter.Fill($table)
$cmd.Dispose()

$table | Out-String

$db.Close()
