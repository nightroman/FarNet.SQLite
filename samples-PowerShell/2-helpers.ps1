# This sample uses System.Data.SQLite.DB helpers.

$ErrorActionPreference=1
Add-Type -Path $env:FARHOME\FarNet\Lib\FarNet.SQLite\FarNet.SQLite.dll

$db = [System.Data.SQLite.DB]::new()

$db.Execute(<#sql#>@'
CREATE TABLE [TestCategories]
(
    [CategoryId] INTEGER PRIMARY KEY,
    [Category] TEXT NOT NULL,
    [Remarks] TEXT NULL
);
INSERT INTO TestCategories (Category, Remarks) VALUES ('Task', 'Task remarks');
INSERT INTO TestCategories (Category, Remarks) VALUES ('Warning', 'Warning remarks');
'@)

$db.ExecuteTable('SELECT * FROM TestCategories') | Out-String

$db.Dispose()
