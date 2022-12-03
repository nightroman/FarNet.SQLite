# FarNet.SQLite Release Notes

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
