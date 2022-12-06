[NuGet]: https://www.nuget.org/packages/FarNet.SQLite
[GitHub]: https://github.com/nightroman/FarNet.SQLite
[System.Data.SQLite]: https://system.data.sqlite.org/index.html/doc/trunk/www/index.wiki

# FarNet.SQLite

[System.Data.SQLite] package for FarNet and PowerShell.

## Package

The package is designed for [FarNet](https://github.com/nightroman/FarNet/wiki).
To install FarNet and FarNet.SQLite, follow [these steps](https://github.com/nightroman/FarNet#readme).

The NuGet package [FarNet.SQLite](https://www.nuget.org/packages/FarNet.SQLite)
is installed to `%FARHOME%\FarNet\Lib\FarNet.SQLite`.

**Included assets:**

- `System.Data.SQLite.dll`

    The original .NET API from the SQLite team.

- `FarNet.SQLite.dll`

    Helper methods to simplify typical tasks routine coding.\
    They are designed for C# and F# and used in PowerShell.

- `FarNet.SQLite.psm1`

    The PowerShell module with `FarNet.SQLite.dll` helpers.\
    Consider using the module in scripts, this way is much easier.

- `FarNet.SQLite.ini`

    The configuration file for F# scripts (FarNet.FSharpFar).

## Sample scripts

- [FSharp](samples-FSharp)
- [PowerShell](samples-PowerShell)

## PowerShell module

The installed package includes the PowerShell module. Its cmdlets make work
with FarNet.SQLite in PowerShell easier, especially in interactive sessions.

The module may be used right out of the box, i.e. imported as:

```powershell
Import-Module $env:FARHOME\FarNet\Lib\FarNet.SQLite
```

But it is better to install this module in PowerShell, so that you can:

```powershell
Import-Module FarNet.SQLite
```

This is not just about the shorter command:

- For scripts outside Far Manager, this way does not need the variable `FARHOME` defined.
- In many cases you do not need to import the module, PowerShell discovers module commands.

### Install the module

Use the steps below to "install" the module as a symbolic link or junction.

(1) Choose one of the module directories, see `$env:PSModulePath`. For example:

- `C:\Program Files\WindowsPowerShell\Modules`

    This folder is used by PowerShell Core and Windows PowerShell.
    If you have rights, this is the recommended location.

- `C:\Users\<user>\Documents\PowerShell\Modules`

    This folder is used by PowerShell Core.

- `C:\Users\<user>\Documents\WindowsPowerShell\Modules`

    This folder is used by Windows PowerShell.

(2) Change to the selected directory, and create the symbolic link
`FarNet.SQLite` to the original `FarNet.SQLite` folder:

```powershell
New-Item -Path FarNet.SQLite -ItemType SymbolicLink -Value $env:FARHOME\FarNet\Lib\FarNet.SQLite
```

> Ensure you have the environment variable `FARHOME` defined or adjust the above command.

Alternatively, you may manually create the similar folder junction point in Far
Manager using `AltF6`.

Now you have the PowerShell module installed. You may update the FarNet package
as usual. The symbolic link or junction do not have to be updated, they point
to the same location.

### Explore commands

```powershell
# import the module
Import-Module FarNet.SQLite

# get its commands
Get-Command -Module FarNet.SQLite

# see help
Open-SQLite -?
help Open-SQLite -full
```

### Typical scripts

**Reading data**

```powershell
Import-Module FarNet.SQLite
Open-SQLite db.sqlite -ReadOnly
try {
    # work with Get-SQLite
    ...
}
finally {
    Close-SQLite
}
```

**Writing data**


```powershell
Import-Module FarNet.SQLite
Open-SQLite db.sqlite -Transaction
try {
    # work with Get-SQLite and Set-SQLite
    ...
    # commit work
    Complete-SQLite
}
finally {
    Close-SQLite
}
```

## See also

- [FarNet.SQLite Release Notes](https://github.com/nightroman/FarNet.SQLite/blob/main/Release-Notes.md)
- [System.Data.SQLite]
- [SQLite](https://sqlite.org/index.html)
