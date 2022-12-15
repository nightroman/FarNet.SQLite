using System;
using System.Data.SQLite;
using System.Management.Automation;

namespace PS.FarNet.SQLite;

[Cmdlet("Open", "SQLite")]
public sealed class OpenSQLiteCommand : PSCmdlet
{
    [Parameter(Position = 0)]
    public string Database { get; set; }

    [Parameter(Position = 1)]
    public string Options { get; set; }

    [Parameter]
    public SwitchParameter CreateFile { get; set; }

    [Parameter]
    public SwitchParameter Transaction { get; set; }

    [Parameter]
    public SwitchParameter AllowNestedTransactions { get; set; }

    [Parameter]
    public SwitchParameter ForeignKeys { get; set; }

    [Parameter]
    public SwitchParameter ReadOnly { get; set; }

    [Parameter]
    public string Variable { get; set; } = "db";

    protected override void BeginProcessing()
    {
        if (!string.IsNullOrEmpty(Database))
        {
            if (!Database.Equals(":memory:", StringComparison.OrdinalIgnoreCase))
            {
                Database = GetUnresolvedProviderPathFromPSPath(Database);
                if (CreateFile)
                    SQLiteConnection.CreateFile(Database);
            }
        }
        else if (string.IsNullOrEmpty(Options))
        {
            Database = ":memory:";
        }

        var sb = new SQLiteConnectionStringBuilder(Options);

        if (AllowNestedTransactions)
            sb.Flags |= SQLiteConnectionFlags.AllowNestedTransactions;

        if (ForeignKeys)
            sb.ForeignKeys = true;

        if (ReadOnly)
            sb.ReadOnly = true;

        var db = new DB(Database, sb.ConnectionString, Transaction);
        SessionState.PSVariable.Set(Variable, db);
    }
}
