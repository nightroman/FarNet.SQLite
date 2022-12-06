# PowerShell scripts using FarNet.SQLite

Scripts may be invoked in Far Manager by PowerShellFar or without Far Manager by powershell or pwsh.

## Using the module

The simplest way of using FarNet.SQLite in PowerShell is via the module.
If the module is installed (see [README](../README.md)):

```powershell
Import-Module FarNet.SQLite
Open-SQLite ...
...
```

If the module is not installed:

```powershell
Import-Module $env:FARHOME\FarNet\Lib\FarNet.SQLite
Open-SQLite ...
...
```

Note that with the installed module you do not need the environment variable `FARHOME` defined.
This may be important for running scripts without Far Manager.

## Using FarNet.SQLite.dll

Another possible way is using `FarNet.SQLite.dll`, see [2-helpers.ps1](2-helpers.ps1):

```powershell
Add-Type -Path $env:FARHOME\FarNet\Lib\FarNet.SQLite\FarNet.SQLite.dll
$db = [System.Data.SQLite.DB]::new(...)
...
```

> `Add-Type` is not needed if the module is imported.

This way unlikely has any advantages over using the module commands.
`FarNet.SQLite.dll` is mostly for C#, F#, JavaScript (JavaScriptFar).

## Using System.Data.SQLite.dll

Another possible way is using `System.Data.SQLite.dll`, see [1-vanilla.ps1](1-vanilla.ps1):

```powershell
Add-Type -Path $env:FARHOME\FarNet\Lib\FarNet.SQLite\System.Data.SQLite.dll
$db = [System.Data.SQLite.SQLiteConnection]::new()
$db.ConnectionString = ...
$db.Open()
...
```

> `Add-Type` is not needed if the module is imported.

This way needs more coding but it gives the full control and may be used in some cases.
