# FarNet.SQLite Release Notes

## v0.5.0

`DB` methods `ExecuteScalar`, `ExecuteColumn`, `ExecuteLookup` and `Get-SQLite -Scalar|Column|Lookup` convert `DBNull` values to nulls.

## v0.4.3

System.Data.SQLite 1.0.118

## v0.4.2

Maintenance.

## v0.4.1

New cmdlet `Use-SQLiteTransaction` (comes back with known issues resolved).

## v0.4.0

Converted PS module from script to binary. This slightly improves performance
and avoids or works around PowerShell script module limitations and issues.

New cmdlet `Register-SQLiteFunction`. Unlike lower level `BindScalarFunction`,
it is easier to use and preserves returned value types in PowerShell.

## v0.3.2

Implemented `REGEXP` (operator and function).

Added the helper `BindScalarFunction`, mostly for .NET use, not PowerShell.

## v0.3.1

`Get-SQLite -Column` always returns array, including 0 and 1 values.

## v0.3.0

**API**

New helpers for `SQLiteCommand`.

**PS module**

New commands `New-SQLiteCommand`, `New-SQLiteParameter` for "prepared" commands.
`Get-SQLite` and `Set-SQLite` accept prepared `New-SQLiteCommand` as `Command`.
Prepared commands are faster for repeated calls.

PowerShell help moved to `FarNet.SQLite-Help.xml`.

## v0.2.0

**API**

- new helper methods `ExecuteColumn`, `ExecuteLookup`
- new constructor parameter `beginTransaction` and related method `Commit`

**PS module**

`Get-SQLite`: new switches `Column`, `Lookup`.

`Open-SQLite`: new switches `CreateFile`, `Transaction`.

Removed `Use-SQLiteTransaction`. Use `Open-SQLite -Transaction` and `Complete-SQLite` instead.
If you need lower level transactions or nested, use the helper `$db.UseTransaction({...})`
or use transactions with `$db.Connection.BeginTransaction`.

## v0.1.0

Command parameters: `IDictionary` or `SQLiteParameter` for named parameters or objects for positional parameters.
Thus:

- `IDictionary` works as before.
- Positional parameters are supported.
- Tuples as parameters are not supported.

## v0.0.2

System.Data.SQLite 1.0.117, SQLite 3.40.0

## v0.0.1

Published on NuGet.
