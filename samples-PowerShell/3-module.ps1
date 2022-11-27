# This sample uses FarNet.SQLite module.

$ErrorActionPreference=1
Import-Module FarNet.SQLite

Open-SQLite

Set-SQLite <#sql#>@'
CREATE TABLE [TestCategories]
(
    [CategoryId] INTEGER PRIMARY KEY,
    [Category] TEXT NOT NULL,
    [Remarks] TEXT NULL
);
INSERT INTO TestCategories (Category, Remarks) VALUES ('Task', 'Task remarks');
INSERT INTO TestCategories (Category, Remarks) VALUES ('Warning', 'Warning remarks');
'@

Get-SQLite 'SELECT * FROM TestCategories' | Out-String

Close-SQLite
