using System.Data.SQLite;
using System.Management.Automation;

namespace PS.FarNet.SQLite;

[Cmdlet("New", "SQLiteCommand")]
[OutputType(typeof(SQLiteCommand))]
public sealed class NewSQLiteCommandCommand : BaseDBCmdlet
{
    [Parameter(Position = 0, Mandatory = true)]
    public string Command { get; set; }

    [Parameter(Position = 1)]
    public SQLiteParameter[] Parameters { get; set; }

    [Parameter]
    public SwitchParameter Dispose { get; set; }

    [Parameter]
    public override DB Database { get; set; }

    protected override void BeginProcessing()
    {
        base.BeginProcessing();
        WriteObject(Database.CreateCommand(Command, Dispose, Parameters));
    }
}
